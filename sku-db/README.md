# sku-db

This project provides a Model Context Protocol (MCP) server for a SKU Database, implemented via `FastMCP` and `FastAPI`. 

## Features
- Provides MCP tools: `search_products`, `get_product_by_sku`, and `query_products_by_price`.
- Exposes MCP interface over standard I/O (default) or SSE (when `MCP_TRANSPORT=sse` is set).
- Contains a REST endpoint `/health` for health checks.

## Development

Install dependencies using [uv](https://docs.astral.sh/uv/):
```bash
uv sync
```

### Seed the database
```bash
python3 seed.py
```

### Running the server

**Stdio Mode (Default - for integration with MCP clients):**
```bash
uv run python server.py
```

**SSE Mode (For web/HTTP clients):**
```bash
MCP_TRANSPORT=sse uv run uvicorn server:app --reload --port 8080
```
