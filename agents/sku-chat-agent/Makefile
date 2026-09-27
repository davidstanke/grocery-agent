.PHONY: install dev test lint

install:
	agents-cli install

dev:
	agents-cli playground

test:
	uv run pytest tests/unit tests/integration

lint:
	agents-cli lint
