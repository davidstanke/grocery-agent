.PHONY: install dev test lint seed test-mcp

install:
	@echo "Installing dependencies..."
	@echo "Installing sku-db dependencies..."
	cd sku-db && uv sync
	@echo "Installing sku-chat-agent dependencies..."
	cd agents/sku-chat-agent && uv sync
	@echo "Installing live-api-agent dependencies (if applicable)..."
	cd agents/live-api-agent && if command -v uv >/dev/null 2>&1; then uv sync; else echo "uv not found, skipping"; fi

dev:
	@echo "Starting development environment..."
	@echo "To run sku-chat-agent locally: cd agents/sku-chat-agent && agents-cli playground"
	@echo "To run sku-db server locally (SSE mode): cd sku-db && MCP_TRANSPORT=sse uv run uvicorn server:app --reload --port 8080"

seed:
	@echo "Seeding SKU database..."
	cd sku-db && python3 seed.py

test-mcp: seed
	@echo "Running MCP tests..."
	cd sku-db && uv run pytest ../tests/test_mcp_server.py

test: seed
	@echo "Running tests..."
	bash tests/test_scaffold_live_api.sh
	bash tests/test_agentfarm_cleanup.sh
	python3 -m pytest tests/test_sku_db.py
	cd agents/sku-chat-agent && uv run pytest tests/unit tests/integration

lint:
	@echo "Running linter..."
	cd agents/sku-chat-agent && uv run ruff check .
