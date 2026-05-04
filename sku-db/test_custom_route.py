from mcp.server.fastmcp import FastMCP
import asyncio

mcp = FastMCP("test")

@mcp.custom_route("/toolspec.json", methods=["GET"])
def get_toolspec():
    return {"tools": []}

async def main():
    app = mcp.sse_app()
    # Check if the route is in the app
    for route in app.routes:
        if hasattr(route, 'path') and route.path == "/toolspec.json":
            print(f"Found route: {route.path}")

if __name__ == "__main__":
    asyncio.run(main())
