# backend/main.py
from fastapi import FastAPI
import grpc
from concurrent import futures
import threading
import uvicorn

from src.models.gen import item_pb2, item_pb2_grpc
from src.services.item_service import ItemService

app = FastAPI()


# Global servicer instances
item_service = ItemService()


def serve_grpc():
    """Run gRPC server in background thread"""
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))

    # Register your servicers
    item_pb2_grpc.add_ItemServiceServicer_to_server(item_service, server)

    listen_addr = '[::]:9091'
    server.add_insecure_port(listen_addr)

    print(f"🚀 gRPC server listening on {listen_addr}")
    server.start()
    server.wait_for_termination()


# Optional: Add REST endpoints that use the same servicer logic
@app.post("/debug/items")
async def debug_create_item(name: str, description: str, price: float):
    """Debug endpoint that calls the gRPC servicer directly"""
    request = item_pb2.CreateItemRequest(
        name=name,
        description=description,
        price=price
    )

    # Call the servicer method directly
    response = item_service.CreateItem(request, None)

    return {
        "id": response.item.id,
        "name": response.item.name,
        "description": response.item.description,
        "price": response.item.price,
        "created_at": response.item.created_at
    }


@app.get("/debug/items/{item_id}")
async def debug_get_item(item_id: str):
    """Debug endpoint"""
    request = item_pb2.GetItemRequest(id=item_id)
    response = item_service.GetItem(request, None)

    if not response.item.id:
        return {"error": "Item not found"}

    return {
        "id": response.item.id,
        "name": response.item.name,
        "description": response.item.description,
        "price": response.item.price,
        "created_at": response.item.created_at
    }


@app.on_event("startup")
async def startup_event():
    """Start gRPC server when FastAPI starts"""
    # Run gRPC server in a separate thread
    grpc_thread = threading.Thread(target=serve_grpc, daemon=True)
    grpc_thread.start()


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)