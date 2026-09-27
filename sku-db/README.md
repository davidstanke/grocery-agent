# SKU Database (MCP Server)

This is a local SQLite database that provides SKU and product information via the Model Context Protocol (MCP).

## Setup

```bash
uv sync
```

## Seeding Data

```bash
uv run python seed.py
```

## Running the Server

```bash
uv run uvicorn server:app --reload
```