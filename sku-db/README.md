# SKU Database (sku-db)

This project contains the local SQLite database service for handling SKU information. It exposes the database functionality.

## Requirements
- Python >= 3.12
- `uv` package manager

## Development

Install dependencies:
```bash
uv sync
```

Seed the database:
```bash
python3 seed.py
```

Run the API:
```bash
uv run fastapi dev server.py
```

## Testing

Run tests via pytest:
```bash
uv run pytest
```
