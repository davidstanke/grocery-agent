.PHONY: install dev test lint seed test-mcp

install:
	@echo "Installing dependencies..."
	cd sku-db && uv sync
	cd agents/sku-chat-agent && uv sync
	cd agents/live-api-agent && uv sync

dev:
	@echo "Starting development environment..."
	@echo "Run 'uv run python sku-db/server.py' for DB, or 'agents-cli playground' in agent dirs."

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
	cd sku-db && uv run pytest ../tests/test_mcp_server.py
	cd agents/sku-chat-agent && uv run pytest tests/unit tests/integration

lint:
	@echo "Running linter..."
	cd agents/sku-chat-agent && uv run ruff check .
