from fastapi.testclient import TestClient
import pytest

from .conftest import create_test_token

# --- Test Data ---
ACCOUNT_ID = "conv_test_acc_123"
USER_EMAIL = "conv_test_user@example.com"

@pytest.fixture
def auth_headers():
    token = create_test_token(email=USER_EMAIL, account_id=ACCOUNT_ID)
    return {"Authorization": f"Bearer {token}"}

@pytest.fixture
def conversation(test_client: TestClient, auth_headers):
    """
    A fixture to create a conversation for tests to use.
    """
    response = test_client.post(
        "/conversations/",
        headers=auth_headers,
        json={"account_id": ACCOUNT_ID, "participant_ids": []}
    )
    assert response.status_code == 200
    return response.json()


def test_intelligent_websocket_flow(test_client: TestClient, conversation: dict, mock_lor_service):
    """
    Tests the full intelligent message flow:
    1. User sends a message.
    2. User's message is broadcast back.
    3. LOR service is called.
    4. AI response is broadcast back.
    """
    conv_id = conversation["id"]
    token = create_test_token(email=USER_EMAIL, account_id=ACCOUNT_ID)

    with test_client.websocket_connect(f"/ws/{conv_id}?token={token}") as websocket:
        # 1. Client sends a message
        client_message = "Hello, I need help with my subscription."
        websocket.send_json({"content": client_message})

        # 2. Client receives their own message back first
        echo_message = websocket.receive_json()
        assert echo_message["content"] == client_message
        assert echo_message["sender_type"] == "user"

        # 3. Assert that the LOR service was called
        mock_lor_service.post.assert_called_once()
        call_args, call_kwargs = mock_lor_service.post.call_args
        lor_request_data = call_kwargs["json"]
        assert lor_request_data["conversation_id"] == conv_id
        assert lor_request_data["conversation_history"][-1]["content"] == client_message

        # 4. Client receives the AI's response
        ai_message = websocket.receive_json()
        assert ai_message["content"] == "This is an intelligent AI response."
        assert ai_message["sender_type"] == "assistant"
        assert ai_message["conversation_id"] == conv_id
