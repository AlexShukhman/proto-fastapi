package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/grpc-ecosystem/grpc-gateway/v2/runtime"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/protobuf/encoding/protojson"

	// Import your generated protobuf code - add all services here
	item "gateway/gen/item"
	// Add more imports as you add services
)

const (
	pythonBackendAddr = "localhost:9091" // Your Python gRPC server
	gatewayGrpcPort   = ":9090"          // Gateway gRPC port (not really needed)
	gatewayHttpPort   = ":8080"          // Gateway REST port
)

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Handle graceful shutdown
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)
	go func() {
		<-c
		log.Println("Shutting down gracefully...")
		cancel()
	}()

	// Just run the HTTP gateway - no need for intermediate gRPC server
	if err := runHTTPGateway(ctx); err != nil {
		log.Printf("HTTP gateway error: %v", err)
	}
}

// runHTTPGateway creates a direct REST -> Python gRPC proxy
func runHTTPGateway(ctx context.Context) error {
	// Connect directly to Python gRPC server
	conn, err := grpc.DialContext(
		ctx,
		pythonBackendAddr,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
		grpc.WithBlock(),
	)
	if err != nil {
		return fmt.Errorf("failed to dial Python backend: %v", err)
	}
	defer conn.Close()

	// Create gateway mux with better options
	gwmux := runtime.NewServeMux(
		runtime.WithIncomingHeaderMatcher(func(key string) (string, bool) {
			// Forward all headers
			return key, true
		}),
		runtime.WithMarshalerOption(runtime.MIMEWildcard, &runtime.JSONPb{
			MarshalOptions: protojson.MarshalOptions{
				UseProtoNames:   true,
				EmitUnpopulated: true,
			},
			UnmarshalOptions: protojson.UnmarshalOptions{
				DiscardUnknown: true,
			},
		}),
	)

	// Register ALL your services here - this is the only place you need to add them
	registerServices(ctx, gwmux, conn)

	// Create HTTP server with CORS and logging
	server := &http.Server{
		Addr:    gatewayHttpPort,
		Handler: loggingMiddleware(corsMiddleware(gwmux)),
	}

	log.Printf("🚀 Gateway listening on http://localhost%s", gatewayHttpPort)
	log.Printf("📡 Proxying to Python backend at %s", pythonBackendAddr)

	// Start server
	serverErr := make(chan error, 1)
	go func() {
		serverErr <- server.ListenAndServe()
	}()

	// Wait for shutdown
	select {
	case <-ctx.Done():
		log.Println("Shutting down HTTP gateway...")
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		return server.Shutdown(shutdownCtx)
	case err := <-serverErr:
		if err == http.ErrServerClosed {
			return nil
		}
		return err
	}
}

// registerServices - This is the ONLY place you need to add new services
func registerServices(ctx context.Context, gwmux *runtime.ServeMux, conn *grpc.ClientConn) {
	if err := item.RegisterItemServiceHandler(ctx, gwmux, conn); err != nil {
		log.Fatalf("Failed to register ItemService: %v", err)
	}

	// Add new services here - just one line per service:
	// if err := orderv1.RegisterOrderServiceHandler(ctx, gwmux, conn); err != nil {
	//     log.Fatalf("Failed to register OrderService: %v", err)
	// }

	log.Println("✅ All services registered")
}

// CORS middleware
func corsMiddleware(h http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		origin := r.Header.Get("Origin")
		if origin == "" {
			origin = "*"
		}

		w.Header().Set("Access-Control-Allow-Origin", origin)
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS, PATCH")
		w.Header().Set("Access-Control-Allow-Headers", "*")
		w.Header().Set("Access-Control-Allow-Credentials", "true")
		w.Header().Set("Access-Control-Max-Age", "86400")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		h.ServeHTTP(w, r)
	})
}

// Logging middleware
func loggingMiddleware(h http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()

		// Log request
		log.Printf("→ %s %s %s", r.Method, r.URL.Path, r.RemoteAddr)

		// Create a response writer that captures status code
		lrw := &loggingResponseWriter{ResponseWriter: w, statusCode: http.StatusOK}

		h.ServeHTTP(lrw, r)

		// Log response
		duration := time.Since(start)
		log.Printf("← %s %s %d %v", r.Method, r.URL.Path, lrw.statusCode, duration)
	})
}

type loggingResponseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (lrw *loggingResponseWriter) WriteHeader(code int) {
	lrw.statusCode = code
	lrw.ResponseWriter.WriteHeader(code)
}
