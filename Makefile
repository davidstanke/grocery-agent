.PHONY: install dev test lint seed test-mcp

install:
	@echo "Installing dependencies..."
	cd sku-db && uv sync
	cd agents/live-api-agent && uv sync
	cd agents/sku-chat-agent && uv sync

dev:
	@echo "Starting development environment..."
	@echo "Run specific components using their respective start commands."
	@echo "For example:"
	@echo "  sku-db: cd sku-db && uv run python server.py"
	@echo "  sku-chat-agent: cd agents/sku-chat-agent && uv run python -m app.agent_runtime_app"

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
	cd sku-db && uv run ruff check .
	cd agents/live-api-agent && uv run ruff check .
	cd agents/sku-chat-agent && uv run ruff check .
