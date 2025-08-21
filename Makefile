# Python and Django Makefile
PYTHON = python3.13
PIP = $(PYTHON) -m pip
VENV = .venv
VENV_BIN = $(VENV)/bin
VENV_PYTHON = $(VENV_BIN)/python
VENV_PIP = $(VENV_BIN)/pip

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
	@echo "  run         - Run FastAPI development server"
	@echo "  test        - Run tests"
	@echo "  test-cov    - Run tests with coverage"
	@echo "  lint        - Run code linting with flake8"
	@echo "  format      - Format code with black"

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
	$(VENV_PIP) install -r requirements.txt

.PHONY: dev-install
dev-install:
	@if [ ! -d "$(VENV)" ]; then \
		echo "Virtual environment not found. Creating..."; \
		$(MAKE) venv; \
	fi
	@if [ -f requirements-dev.txt ]; then \
		$(VENV_PIP) install -r requirements-dev.txt; \
	else \
		$(VENV_PIP) install flake8 black pytest pytest-django pytest-cov; \
	fi

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

# Django commands (check for venv first)
.PHONY: run
run:
	@if [ ! -d "$(VENV)" ]; then \
		echo "Virtual environment not found. Please run 'make setup' first."; \
		exit 1; \
	fi

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
dev: setup run

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