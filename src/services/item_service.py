import uuid

from src.models.gen import item_pb2_grpc, item_pb2


class ItemService(item_pb2_grpc.ItemServiceServicer):
    def __init__(self):
        self.items = {}

    def Echo(self, request, context):
        """Implement the Echo RPC method - just returns the same item"""
        print(f"📦 Received Echo request for item: {request.name}")

        # You can modify the item or just return it as-is
        # For now, let's add an ID if it doesn't have one
        response_item = item_pb2.Item(
            id=request.id if request.id else str(uuid.uuid4()),
            name=request.name,
            value=request.value
        )

        return response_item