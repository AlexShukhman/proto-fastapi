from fastapi import FastAPI

from typing import Type
from protobuf_to_pydantic import msg_to_pydantic_model
from pydantic import BaseModel
from src.models.gen import item_pb2

app = FastAPI()

Item: Type[BaseModel] = msg_to_pydantic_model(item_pb2.Item)

@app.get("/")
def read_root():
    return {"Hello": "World"}


@app.post("/items/", response_model=Item)
def create_item(item: Item):
    return item


@app.get("/items/{item_id}", response_model=Item)
def read_item(item_id: int, q: str = None):
    return item_pb2
