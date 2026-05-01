.PHONY: install dev test lint

install:
	@echo "Installing dependencies..."
	@# Add installation commands here

dev:
	@echo "Starting development environment..."
	@# Add dev commands here

test:
	@echo "Running tests..."
	bash tests/test_scaffold_live_api.sh
	bash tests/test_agentfarm_cleanup.sh
	python3 -m pytest tests/test_sku_db.py

lint:
	@echo "Running linter..."
	@# Add lint commands here
