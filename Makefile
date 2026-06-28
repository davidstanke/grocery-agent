.PHONY: install dev test lint seed test-mcp

install:
	@echo "Installing dependencies..."
	@if [ -f sku-db/pyproject.toml ]; then cd sku-db && uv sync; fi
	@if [ -f agents/sku-chat-agent/pyproject.toml ]; then cd agents/sku-chat-agent && uv sync --extra lint; fi
	@if [ -f agents/live-api-agent/pyproject.toml ]; then cd agents/live-api-agent && uv sync; fi

dev:
	@echo "Starting development environment..."
	@echo "Run 'cd sku-db && uv run fastapi dev server.py' for the database"
	@echo "Run 'cd agents/sku-chat-agent && uv run app/agent_runtime_app.py' for the agent"

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
	@if [ -d agents/sku-chat-agent ]; then cd agents/sku-chat-agent && uv run ruff check .; fi
