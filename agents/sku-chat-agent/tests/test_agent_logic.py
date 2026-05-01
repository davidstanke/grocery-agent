import pytest
from unittest.mock import patch, MagicMock, AsyncMock
from google.genai import types
from google.adk.tools import FunctionTool, BaseTool

def mock_search_products(query: str):
    pass

class DummyMcpToolset(BaseTool):
    def __init__(self, *args, **kwargs):
        self.tools = []
        self.name = "mcp_toolset"
    
    async def process_llm_request(self, llm_request, **kwargs):
        llm_request.append_tools(self.tools)

@pytest.fixture
def isolated_agent(monkeypatch):
    import sys
    if "app.agent" in sys.modules:
        del sys.modules["app.agent"]
    
    with patch("google.auth.default", return_value=(MagicMock(), "fake_project")), \
         patch("google.adk.tools.mcp_tool.McpToolset", new=DummyMcpToolset):
        from app.agent import root_agent
        yield root_agent, DummyMcpToolset

@patch("google.genai.Client")
def test_agent_intent_search_products(mock_genai_client, isolated_agent):
    root_agent, mcp_toolset_class = isolated_agent

    # 1. Setup mocks
    # Find the DummyMcpToolset instance in the agent
    dummy_mcp_instance = root_agent.tools[0]
    
    mock_tool = FunctionTool(mock_search_products)
    dummy_mcp_instance.tools = [mock_tool]

    # 2. Mock the LLM client to return a mock response with a tool call
    mock_client_instance = mock_genai_client.return_value
    mock_response = types.GenerateContentResponse(
        candidates=[
            types.Candidate(
                content=types.Content(
                    parts=[
                        types.Part(
                            function_call=types.FunctionCall(
                                name="mock_search_products",
                                args={"query": "apples"}
                            )
                        )
                    ]
                )
            )
        ]
    )
    mock_aio = MagicMock()
    mock_aio.models.generate_content = AsyncMock(return_value=mock_response)
    mock_client_instance.aio = mock_aio

    # 3. Simulate a run using adk's Runner to see if intent works
    from google.adk.runners import Runner
    from google.adk.sessions import InMemorySessionService
    
    session_service = InMemorySessionService()
    session = session_service.create_session_sync(user_id="test_user", app_name="test")
    runner = Runner(agent=root_agent, session_service=session_service, app_name="test")
    
    message = types.Content(
        role="user", parts=[types.Part.from_text(text="Find apples")]
    )
    
    events = list(
        runner.run(
            new_message=message,
            user_id="test_user",
            session_id=session.id,
        )
    )
    
    # Assert that generate_content was called (LLM was invoked)
    assert mock_client_instance.aio.models.generate_content.called
    
    tool_call_events = [e for e in events if getattr(e, 'tool_call', None) is not None or getattr(e, 'function_call', None) is not None or (getattr(e, 'content', None) and any(getattr(p, 'function_call', None) for p in e.content.parts))]
    
    assert len(tool_call_events) > 0, "Expected a tool call event for 'mock_search_products'"
