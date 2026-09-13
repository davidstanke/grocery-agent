.PHONY: install dev test lint seed test-mcp

install:
	@echo "Installing dependencies..."
	cd sku-db && uv sync
	cd agents/sku-chat-agent && uv sync --all-extras

dev:
	@echo "Starting development environments (run separately in different terminals if needed)"
	@echo "For sku-db: cd sku-db && MCP_TRANSPORT=sse PORT=8080 uv run uvicorn server:app"
	@echo "For sku-chat-agent: cd agents/sku-chat-agent && uv run python -m app.fast_api_app"

seed:
	@echo "Seeding SKU database..."
	python3 sku-db/seed.py

test-mcp: seed
	@echo "Running MCP tests..."
	cd sku-db && uv run pytest ../tests/test_mcp_server.py

test: seed
	@echo "Running tests..."
	bash tests/test_scaffold_live_api.sh
	bash tests/test_agentfarm_cleanup.sh
	python3 -m pytest tests/test_sku_db.py

lint:
	@echo "Running linter..."
	cd agents/sku-chat-agent && uv run ruff check .
