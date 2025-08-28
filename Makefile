# Python and Django Makefile
PYTHON = python3.13
PIP = $(PYTHON) -m pip
VENV = .venv
VENV_BIN = $(VENV)/bin
VENV_PYTHON = $(VENV_BIN)/python
VENV_PIP = $(VENV_BIN)/pip
MODELS = src/models

# Default target
.PHONY: help
help:
	@echo "Available commands:"
	@echo "  setup       - Create virtual environment and install dependencies"
	@echo "  venv        - Create virtual environment only"
	@echo "  activate    - Show command to activate virtual environment"
	@echo "  install     - Install dependencies from requirements.txt"
	@echo "  dev-install - Install development dependencies"
	@echo "  freeze      - Generate requirements.txt from current environment"
	@echo "  clean       - Remove virtual environment and cache files"
	@echo "  clean-cache - Remove only cache files (keep venv)"
	@echo "  run-python      - Run Python FastAPI server"
	@echo "  run-gateway     - Run Go gateway server"
	@echo "  start           - Start Go gateway server (alias for run-gateway)"
	@echo "  build-gateway   - Build Go gateway server binaries (OS aware)"
	@echo "  generate        - Generate protobuf files using buf"
	@echo "  dev             - Start both Python and gateway servers simultaneously"
	@echo "  test            - Run tests"
	@echo "  test-cov        - Run tests with coverage"
	@echo "  lint            - Run code linting with flake8"
	@echo "  format          - Format code with black"
	@echo "  status          - Show project status and dependencies"
	@echo "  protos          - Generate protobuf Python files (legacy)"

# Virtual environment setup
.PHONY: venv
venv:
	$(PYTHON) -m venv $(VENV)
	$(VENV_PIP) install --upgrade pip
	@echo "Virtual environment created in $(VENV)/"
	@echo "To activate: source $(VENV_BIN)/activate"

.PHONY: setup
setup: venv
	@if [ -f requirements.txt ]; then \
		echo "Installing from requirements.txt..."; \
		$(VENV_PIP) install -r requirements.txt; \
	else \
		echo "No requirements.txt found, installing basic packages..."; \
		$(VENV_PIP) install django; \
	fi
	@echo "Setup complete. To activate venv: source $(VENV_BIN)/activate"

.PHONY: activate
activate:
	@echo "To activate the virtual environment, run:"
	@echo "source $(VENV_BIN)/activate"

# Dependencies
.PHONY: install
install:
	@if [ ! -d "$(VENV)" ]; then \
		echo "Virtual environment not found. Creating..."; \
		$(MAKE) venv; \
	fi
	$(VENV_PIP) install --only-binary=pydantic-core -r requirements.txt;

.PHONY: freeze
freeze:
	@if [ ! -d "$(VENV)" ]; then \
		echo "Virtual environment not found. Please run 'make venv' first."; \
		exit 1; \
	fi
	$(VENV_PIP) freeze > requirements.txt

# Cleanup
.PHONY: clean
clean:
	rm -rf $(VENV)
	$(MAKE) clean-cache

.PHONY: clean-cache
clean-cache:
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	rm -rf .pytest_cache
	rm -rf .coverage
	rm -rf htmlcov
	rm -rf dist
	rm -rf build

# Start server (check for venv first)
.PHONY: run-python
run-python:
	@if [ ! -d "$(VENV)" ]; then \
		echo "Virtual environment not found. Please run 'make setup' first."; \
		exit 1; \
	fi
	$(VENV_PYTHON) -m uvicorn src.server:app --reload --host 0.0.0.0 --port 8000

# Build gateway server (OS aware)
.PHONY: build-gateway
build-gateway:
	@echo "Building gateway server..."
	@mkdir -p bin
	cd src/gateway && \
	if [ "$(shell uname)" = "Darwin" ]; then \
		GOOS=darwin GOARCH=amd64 go build -o ../../bin/gateway-darwin-amd64 main.go && \
		GOOS=darwin GOARCH=arm64 go build -o ../../bin/gateway-darwin-arm64 main.go && \
		echo "Built gateway for macOS (Intel and Apple Silicon)"; \
	elif [ "$(shell uname)" = "Linux" ]; then \
		GOOS=linux GOARCH=amd64 go build -o ../../bin/gateway-linux-amd64 main.go && \
		GOOS=linux GOARCH=arm64 go build -o ../../bin/gateway-linux-arm64 main.go && \
		echo "Built gateway for Linux (amd64 and arm64)"; \
	elif [ "$(shell uname -s | cut -c1-5)" = "MINGW" ] || [ "$(shell uname -s | cut -c1-4)" = "MSYS" ]; then \
		GOOS=windows GOARCH=amd64 go build -o ../../bin/gateway-windows-amd64.exe main.go && \
		GOOS=windows GOARCH=arm64 go build -o ../../bin/gateway-windows-arm64.exe main.go && \
		echo "Built gateway for Windows (amd64 and arm64)"; \
	else \
		go build -o ../../bin/gateway main.go && \
		echo "Built gateway for current platform"; \
	fi

# Start gateway server
.PHONY: run-gateway
run-gateway: build-gateway
	cd src/gateway && go run main.go

# Testing
.PHONY: test
test:
	@if [ ! -d "$(VENV)" ]; then \
		echo "Virtual environment not found. Please run 'make setup' first."; \
		exit 1; \
	fi
	$(VENV_PYTHON) -m pytest

.PHONY: test-cov
test-cov:
	@if [ ! -d "$(VENV)" ]; then \
		echo "Virtual environment not found. Please run 'make setup' first."; \
		exit 1; \
	fi
	$(VENV_PYTHON) -m pytest --cov=. --cov-report=html --cov-report=term

# Code quality
.PHONY: lint
lint:
	@if [ ! -d "$(VENV)" ]; then \
		echo "Virtual environment not found. Please run 'make setup' first."; \
		exit 1; \
	fi
	$(VENV_PYTHON) -m flake8 .

.PHONY: format
format:
	@if [ ! -d "$(VENV)" ]; then \
		echo "Virtual environment not found. Please run 'make setup' first."; \
		exit 1; \
	fi
	$(VENV_PYTHON) -m black .

# Development workflow
.PHONY: dev
dev: generate install
	@echo "Starting development servers..."
	@echo "Python server will start on port 8000"
	@echo "Gateway server will start on port 8080"
	@echo "Press Ctrl+C to stop both servers"
	$(MAKE) run-python & $(MAKE) run-gateway & wait

# Status check
.PHONY: status
status:
	@echo "Python version: $(shell $(PYTHON) --version)"
	@if [ -d "$(VENV)" ]; then \
		echo "Virtual environment: ✓ Found at $(VENV)/"; \
		echo "Virtual environment Python: $(shell $(VENV_PYTHON) --version)"; \
	else \
		echo "Virtual environment: ✗ Not found"; \
	fi
	@if [ -f requirements.txt ]; then \
		echo "Requirements file: ✓ Found"; \
	else \
		echo "Requirements file: ✗ Not found"; \
	fi

# Protobuf
.PHONY: generate
generate:
	@if [ ! -d "$(VENV)" ]; then \
		echo "Virtual environment not found. Please run 'make setup' first."; \
		exit 1; \
	fi
	PATH="$(VENV_BIN):$$PATH" buf generate
	$(VENV_PYTHON) dev/fix_imports.py