from fastapi.testclient import TestClient
import pytest

from .conftest import create_test_token

# --- Test Data ---
ACCOUNT_ID = "ws_acc_123"
USER_1_EMAIL = "ws_user1@example.com"
USER_2_EMAIL = "ws_user2@example.com"

def test_websocket_communication(test_client: TestClient):
    """
    Tests that two clients can connect to the same conversation
    and receive broadcasted messages.
    """
    # 1. Create a conversation to chat in
    token1 = create_test_token(email=USER_1_EMAIL, account_id=ACCOUNT_ID)
    headers = {"Authorization": f"Bearer {token1}"}
    conv_response = test_client.post(
        "/conversations/",
        headers=headers,
        json={"account_id": ACCOUNT_ID, "participant_ids": []}
    )
    conv_id = conv_response.json()["id"]

    # 2. Connect two clients to the WebSocket endpoint
    token2 = create_test_token(email=USER_2_EMAIL, account_id=ACCOUNT_ID)

    with test_client.websocket_connect(f"/ws/{conv_id}?token={token1}") as websocket1, \
         test_client.websocket_connect(f"/ws/{conv_id}?token={token2}") as websocket2:

        # 3. Client 1 sends a message
        websocket1.send_json({"content": "Hello from client 1"})

        # 4. Assert that both clients receive the message
        # The message is first saved, then broadcasted back as a full Message schema object

        # Client 1 receives its own message back
        data1 = websocket1.receive_json()
        assert data1["content"] == "Hello from client 1"
        assert data1["sender_id"] == USER_1_EMAIL
        assert "id" in data1 # It's now a persisted message

        # Client 2 receives the message from client 1
        data2 = websocket2.receive_json()
        assert data2["content"] == "Hello from client 1"
        assert data2["sender_id"] == USER_1_EMAIL

        # 5. Client 2 sends a reply
        websocket2.send_json({"content": "Hello back from client 2"})

        # 6. Assert both clients receive the reply
        reply1 = websocket1.receive_json()
        assert reply1["content"] == "Hello back from client 2"
        assert reply1["sender_id"] == USER_2_EMAIL

        reply2 = websocket2.receive_json()
        assert reply2["content"] == "Hello back from client 2"
        assert reply2["sender_id"] == USER_2_EMAIL


def test_websocket_authentication_failure(test_client: TestClient):
    """
    Tests that the WebSocket connection is rejected for an invalid token.
    """
    conv_id = "conv_unauthed_test"
    invalid_token = "this.is.not.a.valid.token"

    with pytest.raises(Exception) as e:
        # The TestClient's websocket_connect will raise an exception if the connection is closed with an error code.
        with test_client.websocket_connect(f"/ws/{conv_id}?token={invalid_token}"):
            pass # We don't expect this to succeed

    # We can't easily assert the close code with the TestClient,
    # but the fact that it raises an exception on connection failure is a good sign.
    assert e is not None

def test_websocket_permission_denied(test_client: TestClient):
    """
    Tests that a user cannot connect to a conversation in another account.
    """
    # Create a conversation for ACCOUNT_ID
    token1 = create_test_token(email=USER_1_EMAIL, account_id=ACCOUNT_ID)
    headers = {"Authorization": f"Bearer {token1}"}
    conv_response = test_client.post(
        "/conversations/",
        headers=headers,
        json={"account_id": ACCOUNT_ID, "participant_ids": []}
    )
    conv_id = conv_response.json()["id"]

    # Attempt to connect as a user from a different account
    other_account_id = "ws_acc_other"
    token_other = create_test_token(email="other@example.com", account_id=other_account_id)

    with pytest.raises(Exception) as e:
        with test_client.websocket_connect(f"/ws/{conv_id}?token={token_other}"):
            pass

    assert e is not None
