from fastapi.testclient import TestClient
from .conftest import create_test_token

# --- Test Data ---
ACCOUNT_ID_1 = "acc_11111"
ACCOUNT_ID_2 = "acc_22222"
USER_EMAIL_1 = "user1@example.com"
USER_EMAIL_2 = "user2@example.com"

def test_create_conversation(test_client: TestClient):
    """
    Tests creating a conversation.
    """
    token = create_test_token(email=USER_EMAIL_1, account_id=ACCOUNT_ID_1)
    headers = {"Authorization": f"Bearer {token}"}

    response = test_client.post(
        "/conversations/",
        headers=headers,
        json={"account_id": ACCOUNT_ID_1, "participant_ids": ["contact_123"]}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["account_id"] == ACCOUNT_ID_1
    assert "id" in data

def test_cannot_create_conversation_for_other_account(test_client: TestClient):
    """
    Tests that a user cannot create a conversation for an account they don't belong to.
    """
    token = create_test_token(email=USER_EMAIL_1, account_id=ACCOUNT_ID_1)
    headers = {"Authorization": f"Bearer {token}"}

    response = test_client.post(
        "/conversations/",
        headers=headers,
        json={"account_id": ACCOUNT_ID_2, "participant_ids": ["contact_456"]} # Mismatched account_id
    )
    assert response.status_code == 403
    assert response.json() == {"detail": "Not authorized to create conversations for this account"}

def test_list_conversations_scoped_to_account(test_client: TestClient):
    """
    Tests that listing conversations is properly scoped to the user's account.
    """
    # Create conversation for account 1
    token1 = create_test_token(email=USER_EMAIL_1, account_id=ACCOUNT_ID_1)
    headers1 = {"Authorization": f"Bearer {token1}"}
    test_client.post("/conversations/", headers=headers1, json={"account_id": ACCOUNT_ID_1, "participant_ids": []})

    # Create conversation for account 2
    token2 = create_test_token(email=USER_EMAIL_2, account_id=ACCOUNT_ID_2)
    headers2 = {"Authorization": f"Bearer {token2}"}
    test_client.post("/conversations/", headers=headers2, json={"account_id": ACCOUNT_ID_2, "participant_ids": []})

    # List conversations as user 1
    response1 = test_client.get("/conversations/", headers=headers1)
    assert response1.status_code == 200
    data1 = response1.json()
    assert len(data1) == 1
    assert data1[0]["account_id"] == ACCOUNT_ID_1

def test_get_messages_for_conversation(test_client: TestClient, db_session):
    """
    Tests fetching the message history for a conversation.
    This test requires direct DB interaction to add messages.
    """
    from app import crud, schemas

    # Create a conversation via the API
    token = create_test_token(email=USER_EMAIL_1, account_id=ACCOUNT_ID_1)
    headers = {"Authorization": f"Bearer {token}"}
    conv_response = test_client.post("/conversations/", headers=headers, json={"account_id": ACCOUNT_ID_1, "participant_ids": []})
    conv_id = conv_response.json()["id"]

    # Add messages directly using CRUD for this test
    msg1 = schemas.MessageCreate(content="Hello", sender_id="user1", sender_type="user")
    msg2 = schemas.MessageCreate(content="Hi there", sender_id="contact1", sender_type="contact")
    crud.create_message_in_conversation(db_session, msg1, conv_id)
    crud.create_message_in_conversation(db_session, msg2, conv_id)

    # Fetch the messages via the API
    response = test_client.get(f"/conversations/{conv_id}/messages", headers=headers)
    assert response.status_code == 200
    messages = response.json()
    assert len(messages) == 2
    assert messages[0]["content"] == "Hello"
    assert messages[1]["content"] == "Hi there"
