from fastapi.testclient import TestClient
from .conftest import create_test_token

# --- Test Data ---
ACCOUNT_ID_1 = "acc_11111"
ACCOUNT_ID_2 = "acc_22222"
USER_EMAIL_1 = "user1@example.com"
USER_EMAIL_2 = "user2@example.com"


def test_unauthenticated_access(test_client: TestClient):
    """
    Tests that unauthenticated requests are rejected.
    """
    response = test_client.get("/contacts/")
    assert response.status_code == 401
    assert response.json() == {"detail": "Not authenticated"}

def test_create_and_get_contact(test_client: TestClient):
    """
    Tests creating a contact and ensuring it's linked to the correct account.
    """
    token = create_test_token(email=USER_EMAIL_1, account_id=ACCOUNT_ID_1)
    headers = {"Authorization": f"Bearer {token}"}

    # Create a contact for account 1
    response = test_client.post(
        "/contacts/",
        headers=headers,
        json={"email": "contact1@example.com", "account_id": ACCOUNT_ID_1}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == "contact1@example.com"
    assert data["account_id"] == ACCOUNT_ID_1
    contact_id = data["id"]

    # Retrieve the contact
    response = test_client.get(f"/contacts/{contact_id}", headers=headers)
    assert response.status_code == 200
    assert response.json()["id"] == contact_id

def test_list_contacts_scoped_to_account(test_client: TestClient):
    """
    Tests that listing contacts only returns contacts for the user's account.
    """
    # Create a contact for account 1
    token1 = create_test_token(email=USER_EMAIL_1, account_id=ACCOUNT_ID_1)
    headers1 = {"Authorization": f"Bearer {token1}"}
    test_client.post("/contacts/", headers=headers1, json={"email": "c1@example.com", "account_id": ACCOUNT_ID_1})

    # Create a contact for account 2
    token2 = create_test_token(email=USER_EMAIL_2, account_id=ACCOUNT_ID_2)
    headers2 = {"Authorization": f"Bearer {token2}"}
    test_client.post("/contacts/", headers=headers2, json={"email": "c2@example.com", "account_id": ACCOUNT_ID_2})

    # List contacts as user 1
    response1 = test_client.get("/contacts/", headers=headers1)
    assert response1.status_code == 200
    data1 = response1.json()
    assert len(data1) == 1
    assert data1[0]["email"] == "c1@example.com"
    assert data1[0]["account_id"] == ACCOUNT_ID_1

    # List contacts as user 2
    response2 = test_client.get("/contacts/", headers=headers2)
    assert response2.status_code == 200
    data2 = response2.json()
    assert len(data2) == 1
    assert data2[0]["email"] == "c2@example.com"
    assert data2[0]["account_id"] == ACCOUNT_ID_2

def test_cannot_access_contact_from_other_account(test_client: TestClient):
    """
    Tests that a user cannot get, update, or delete a contact from another account.
    """
    # Create a contact for account 1
    token1 = create_test_token(email=USER_EMAIL_1, account_id=ACCOUNT_ID_1)
    headers1 = {"Authorization": f"Bearer {token1}"}
    response = test_client.post("/contacts/", headers=headers1, json={"email": "cross@example.com", "account_id": ACCOUNT_ID_1})
    contact_id = response.json()["id"]

    # Try to access it as user 2
    token2 = create_test_token(email=USER_EMAIL_2, account_id=ACCOUNT_ID_2)
    headers2 = {"Authorization": f"Bearer {token2}"}

    # GET
    get_response = test_client.get(f"/contacts/{contact_id}", headers=headers2)
    assert get_response.status_code == 403
    assert get_response.json() == {"detail": "Not authorized to access this contact"}

    # PUT
    put_response = test_client.put(f"/contacts/{contact_id}", headers=headers2, json={"first_name": "Hacker"})
    assert put_response.status_code == 403
    assert put_response.json() == {"detail": "Not authorized to update this contact"}

    # DELETE
    delete_response = test_client.delete(f"/contacts/{contact_id}", headers=headers2)
    assert delete_response.status_code == 403
    assert delete_response.json() == {"detail": "Not authorized to delete this contact"}

def test_manage_custom_attributes(test_client: TestClient):
    """
    Tests adding and deleting custom attributes for a contact.
    """
    token = create_test_token(email=USER_EMAIL_1, account_id=ACCOUNT_ID_1)
    headers = {"Authorization": f"Bearer {token}"}

    # Create a contact
    contact_response = test_client.post(
        "/contacts/",
        headers=headers,
        json={"email": "custom_attr@example.com", "account_id": ACCOUNT_ID_1}
    )
    contact_id = contact_response.json()["id"]

    # Add a custom attribute
    attr_response = test_client.post(
        f"/contacts/{contact_id}/custom_attributes/",
        headers=headers,
        json={"name": "plan_type", "value": "premium"}
    )
    assert attr_response.status_code == 200
    attr_data = attr_response.json()
    assert attr_data["name"] == "plan_type"
    assert attr_data["value"] == "premium"
    attribute_id = attr_data["id"]

    # Verify the attribute is on the contact
    get_contact_response = test_client.get(f"/contacts/{contact_id}", headers=headers)
    contact_data = get_contact_response.json()
    assert len(contact_data["custom_attributes"]) == 1
    assert contact_data["custom_attributes"][0]["name"] == "plan_type"

    # Delete the custom attribute
    delete_attr_response = test_client.delete(f"/custom_attributes/{attribute_id}", headers=headers)
    assert delete_attr_response.status_code == 200

    # Verify it's gone
    get_contact_response_after = test_client.get(f"/contacts/{contact_id}", headers=headers)
    contact_data_after = get_contact_response_after.json()
    assert len(contact_data_after["custom_attributes"]) == 0
