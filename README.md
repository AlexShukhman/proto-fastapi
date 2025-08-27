# fastapi_app
Generic FastAPI app

## Required binaries

- Python
- Makefile
- Buf (for Protobuf generation)
- Golang (for GRPC Gateway)
- Rust (for Pydantic-Core)

## Required go packages

```sh
   go install \
    github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@latest \
    github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@latest \
    google.golang.org/protobuf/cmd/protoc-gen-go@latest \
    google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
```

## Required python packages

```sh
make install
```