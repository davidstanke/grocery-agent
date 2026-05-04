import sqlite3
import json
import logging
import sys
import os
from mcp.server.fastmcp import FastMCP
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

# Configure logging to stderr
logging.basicConfig(level=logging.INFO, stream=sys.stderr)
logger = logging.getLogger(__name__)

mcp = FastMCP("sku-db-server")

DB_PATH = os.path.join(os.path.dirname(__file__), "products.db")

def get_db_connection():
    # Use uri=True to allow read-only mode
    conn = sqlite3.connect(f"file:{DB_PATH}?mode=ro", uri=True)
    conn.row_factory = sqlite3.Row
    return conn

@mcp.tool()
def search_products(query: str) -> str:
    """Search products by free-text partial matching against name and description."""
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            like_query = f"%{query}%"
            cursor.execute(
                "SELECT * FROM skus WHERE name LIKE ? OR description LIKE ?",
                (like_query, like_query)
            )
            rows = cursor.fetchall()
            return json.dumps([dict(row) for row in rows])
    except Exception as e:
        logger.error(f"Error in search_products: {e}")
        return json.dumps([])

@mcp.tool()
def get_product_by_sku(sku: int) -> str:
    """Get a single product record using its integer SKU."""
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM skus WHERE sku = ?", (sku,))
            row = cursor.fetchone()
            if row:
                return json.dumps(dict(row))
            return json.dumps(None)
    except Exception as e:
        logger.error(f"Error in get_product_by_sku: {e}")
        return json.dumps(None)

@mcp.tool()
def query_products_by_price(min_price: float = 0.0, max_price: float = None) -> str:
    """Filter products by an exact price or a price range."""
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            query = "SELECT * FROM skus WHERE price >= ?"
            params = [min_price]
            
            if max_price is not None:
                query += " AND price <= ?"
                params.append(max_price)
                
            cursor.execute(query, tuple(params))
            rows = cursor.fetchall()
            return json.dumps([dict(row) for row in rows])
    except Exception as e:
        logger.error(f"Error in query_products_by_price: {e}")
        return json.dumps([])

@mcp.custom_route("/toolspec.json", methods=["GET","POST"])
async def get_toolspec(request):
    """Expose tool definitions in the format expected by Gemini Enterprise Agent Platform."""
    tools = await mcp.list_tools()
    data = {
        "tools": [
            {
                "name": tool.name,
                "description": tool.description,
                "inputSchema": tool.inputSchema,
            }
            for tool in tools
        ]
    }
    return JSONResponse(content=data)

# Create the parent FastAPI application
app = FastAPI(title="SKU DB MCP Server")

# Add CORS middleware for public accessibility
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Health check endpoint
@app.get("/health")
async def health():
    return {"status": "ok"}

# Mount the MCP SSE application at /mcp
app.mount("/mcp", mcp.sse_app())

if __name__ == "__main__":
    if os.environ.get("MCP_TRANSPORT") == "sse":
        import uvicorn
        port = int(os.environ.get("PORT", "8080"))
        logger.info(f"Starting MCP SSE server on port {port} at /mcp")
        uvicorn.run(app, host="0.0.0.0", port=port)
    else:
        # Ensure standard output strictly reserved for MCP protocol
        mcp.run(transport='stdio')
