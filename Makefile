.PHONY: install dev test lint seed test-mcp

install:
	@echo "Installing root dependencies..."
	$(MAKE) -C sku-db install
	$(MAKE) -C agents/live-api-agent install
	$(MAKE) -C agents/sku-chat-agent install

dev:
	@echo "Starting development environment..."
	@echo "Run specific subprojects using make -C <dir> dev"

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
	$(MAKE) -C sku-db test || true
	$(MAKE) -C agents/sku-chat-agent test || true
	$(MAKE) -C agents/live-api-agent test || true

lint:
	@echo "Running linter..."
	$(MAKE) -C sku-db lint || true
	$(MAKE) -C agents/live-api-agent lint || true
	$(MAKE) -C agents/sku-chat-agent lint || true
