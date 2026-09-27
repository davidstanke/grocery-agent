.PHONY: install dev test lint

install:
	uv sync

dev:
	uv run uvicorn server:app --reload --port 8000

test:
	uv run pytest

lint:
	@echo "No linter configured for sku-db yet."
