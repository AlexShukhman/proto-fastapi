# Proto FastAPI
FastAPI app behind a reverse proxy that converts GRPC to REST

## Required binaries

- Python
- Makefile
- Buf (for Protobuf generation)
- Golang (for GRPC Gateway)
- Rust (for Pydantic-Core)

## Intention

We want to be able to make a scalable REST API that works entirely off of a .proto definition. We chose FastAPI to use as the backend because it's simple, has a relatively comfortable GRPC implementation, and seems more efficient than the native GRPC Python implementation.

This will act as a template for future projects.