.PHONY: install dev test lint seed test-mcp

install:
	@echo "Installing dependencies..."
	@# Add installation commands here

dev:
	@echo "Starting development environment..."
	@# Add dev commands here

seed:
	@echo "Seeding SKU database..."
	python3 sku-db/seed.py

test-mcp: seed
	@echo "Running MCP tests..."
	python3 -m pytest tests/test_mcp_server.py

test: seed
	@echo "Running tests..."
	bash tests/test_scaffold_live_api.sh
	bash tests/test_agentfarm_cleanup.sh
	python3 -m pytest tests/test_sku_db.py

lint:
	@echo "Running linter..."
	@# Add lint commands here
