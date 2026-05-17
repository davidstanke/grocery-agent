.PHONY: install dev test lint seed test-mcp

install:
	@echo "Installing dependencies..."
	cd sku-db && uv sync
	cd agents/sku-chat-agent && uv sync
	cd agents/live-api-agent && uv sync

dev:
	@echo "Starting development environment..."
	@echo "To run the SKU DB: cd sku-db && uv run python server.py"
	@echo "To run the Agent: cd agents/sku-chat-agent && uv run uvicorn app.fast_api_app:app --reload"

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
