from fastapi.testclient import TestClient
from unittest.mock import ANY

# We assume conftest.py provides the test_client and mock_clients fixtures

def test_orchestrate_turn_success(test_client: TestClient, mock_clients):
    """
    Tests a successful orchestration of a conversational turn.
    """
    mock_http_client, mock_llm_client = mock_clients

    request_data = {
        "conversation_id": "conv_123",
        "conversation_history": [
            {"role": "user", "content": "I need to reschedule my appointment."}
        ],
        "context": {"episode_id": "ep_456"},
        "flow_id": "appointment_reschedule_v3"
    }

    response = test_client.post("/orchestrate", json=request_data)

    # 1. Assert the API response is successful
    assert response.status_code == 200
    data = response.json()
    assert data["conversation_id"] == "conv_123"
    assert "This is a mock LLM response" in data["response_message"]

    # 2. Assert the Decision Trace is correct
    trace = data["decision_trace"]
    assert trace["model_used"] == "gpt-4o"
    assert len(trace["retrieval"]["docs"]) > 0
    assert trace["retrieval"]["docs"][0]["id"] == "kb://reschedule_policy"

    # 3. Assert that the external services were called
    # Check that SOR service was called for the knowledge base
    mock_http_client.post.assert_called_once()
    # Check that the LLM was called
    mock_llm_client.chat.completions.create.assert_called_once()

    # Check that the prompt sent to the LLM contained the retrieved context
    call_args, call_kwargs = mock_llm_client.chat.completions.create.call_args
    llm_messages = call_kwargs["messages"]
    system_prompt = llm_messages[0]["content"]
    assert "Our policy allows rescheduling" in system_prompt


def test_orchestrate_invalid_flow(test_client: TestClient):
    """
    Tests that requesting a non-existent flow returns a 404 error.
    """
    request_data = {
        "conversation_id": "conv_123",
        "conversation_history": [],
        "context": {},
        "flow_id": "non_existent_flow"
    }

    response = test_client.post("/orchestrate", json=request_data)

    assert response.status_code == 404
    assert response.json() == {"detail": "Flow with id 'non_existent_flow' not found"}
