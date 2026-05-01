# ruff: noqa
import os
from google.adk.agents import Agent
from google.adk.apps import App
from google.adk.models import Gemini
from google.genai import types
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from mcp import StdioServerParameters
import google.auth
from google.auth.exceptions import DefaultCredentialsError

try:
    _, project_id = google.auth.default()
except DefaultCredentialsError:
    project_id = "test-project"

os.environ["GOOGLE_CLOUD_PROJECT"] = project_id or "test-project"
os.environ["GOOGLE_CLOUD_LOCATION"] = "global"
os.environ["GOOGLE_GENAI_USE_VERTEXAI"] = "True"

server_py_path = os.environ.get("SKU_DB_SERVER_PATH", os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../sku-db/server.py")))

mcp_toolset = McpToolset(
    connection_params=StdioConnectionParams(
        server_params=StdioServerParameters(
            command="python",
            args=[server_py_path],
        )
    ),
    tool_filter=["search_products", "get_product_by_sku", "query_products_by_price"],
)

root_agent = Agent(
    name="sku_chat_agent",
    model=Gemini(
        model="gemini-flash-latest",
        retry_options=types.HttpRetryOptions(attempts=3),
    ),
    description="A conversational agent that connects to the sku-db service to manage products.",
    instruction="You are a helpful AI assistant that searches for products, looks up product details by SKU, and queries products by price.",
    tools=[mcp_toolset],
)

app = App(
    root_agent=root_agent,
    name="app",
)

if __name__ == "__main__":
    from google.adk.a2a.utils.agent_to_a2a import to_a2a
    to_a2a(root_agent, port=8001)
