import os
from mcp.server.fastmcp import FastMCP
mcp = FastMCP("test")
if __name__ == "__main__":
    # This will likely block, so I'll run it in background or just check code
    print("Starting...")
    mcp.run(transport='sse')
