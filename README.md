# fastapi_app
FastAPI app behind a reverse proxy that converts GRPC to REST

## Required binaries

- Python
- Makefile
- Buf (for Protobuf generation)
- Golang (for GRPC Gateway)
- Rust (for Pydantic-Core)

## Intention

We want to be able to make a REST API that works entirely off of a .proto definition.