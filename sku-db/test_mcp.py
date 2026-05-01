from mcp.server.fastmcp import FastMCP
mcp = FastMCP("test")
try:
    mcp.run(transport='sse', port=8080)
except TypeError as e:
    print(f"Caught expected TypeError: {e}")
