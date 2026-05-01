import pytest
from unittest.mock import patch, MagicMock

# We need to mock google.auth.default before app.agent is imported
with patch("google.auth.default", return_value=(MagicMock(), "fake_project")):
    from app.agent import root_agent

@patch("app.agent.McpToolset", create=True)
@patch("google.genai.Client")
def test_agent_intent_search_products(mock_genai_client, mock_mcp_toolset):
    """
    Test that the agent is configured with the expected McpToolset and that 
    a user query correctly triggers the intent to call search_products.
    """
    # 1. Setup mocks
    # Mock the McpToolset instance and its tools
    mock_mcp_instance = mock_mcp_toolset.return_value
    mock_tool = MagicMock()
    mock_tool.name = "search_products"
    mock_mcp_instance.tools = [mock_tool]
    
    # Mock the LLM client to return a mock response with a tool call
    mock_client_instance = mock_genai_client.return_value
    mock_response = MagicMock()
    mock_function_call = MagicMock()
    mock_function_call.name = "search_products"
    mock_function_call.args = {"query": "apples"}
    mock_part = MagicMock()
    mock_part.function_call = mock_function_call
    mock_part.text = None
    mock_response.candidates = [MagicMock(content=MagicMock(parts=[mock_part]))]
    mock_client_instance.models.generate_content.return_value = mock_response

    # 2. Assert agent has the McpToolset configured
    # Right now this will fail because app.agent.py doesn't use McpToolset
    assert "McpToolset" in [type(t).__name__ for t in root_agent.tools], "McpToolset is not configured in the agent"
    
    # 3. Simulate a run using adk's Runner to see if intent works
    from google.adk.runners import Runner
    from google.adk.sessions import InMemorySessionService
    from google.genai import types
    from google.adk.agents.run_config import RunConfig, StreamingMode
    
    session_service = InMemorySessionService()
    session = session_service.create_session_sync(user_id="test_user", app_name="test")
    runner = Runner(agent=root_agent, session_service=session_service, app_name="test")
    
    message = types.Content(
        role="user", parts=[types.Part.from_text(text="Find apples")]
    )
    
    # This should execute and hit our mock, capturing the tool execution attempt
    events = list(
        runner.run(
            new_message=message,
            user_id="test_user",
            session_id=session.id,
        )
    )
    
    # Assert that generate_content was called (LLM was invoked)
    assert mock_client_instance.models.generate_content.called
    
    # If the LLM returned a tool call for search_products, the runner should have yielded a tool call event
    tool_call_events = [e for e in events if getattr(e, 'tool_call', None) is not None or getattr(e, 'function_call', None) is not None or (getattr(e, 'content', None) and any(getattr(p, 'function_call', None) for p in e.content.parts))]
    
    # Depending on exactly what ADK returns, we check if the intent was successfully translated.
    # The test will fail much earlier due to McpToolset missing anyway!
    assert len(tool_call_events) > 0, "Expected a tool call event for 'search_products'"
