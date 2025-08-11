from fastapi.testclient import TestClient

def test_create_account(test_client: TestClient):
    response = test_client.post("/accounts/", json={"name": "Test Account"})
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "Test Account"
    assert "id" in data

def test_create_user(test_client: TestClient):
    # First, create an account
    acc_response = test_client.post("/accounts/", json={"name": "Test Account for User"})
    account_id = acc_response.json()["id"]

    # Now, create a user
    response = test_client.post(
        "/users/",
        json={"email": "test@example.com", "password": "password123", "account_id": account_id}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == "test@example.com"
    assert data["account_id"] == account_id
    assert "id" in data
    assert "hashed_password" not in data

def test_create_duplicate_user(test_client: TestClient):
    acc_response = test_client.post("/accounts/", json={"name": "Another Test Account"})
    account_id = acc_response.json()["id"]

    # Create the first user
    test_client.post(
        "/users/",
        json={"email": "duplicate@example.com", "password": "password123", "account_id": account_id}
    )

    # Attempt to create a second user with the same email
    response = test_client.post(
        "/users/",
        json={"email": "duplicate@example.com", "password": "password456", "account_id": account_id}
    )
    assert response.status_code == 400
    assert response.json() == {"detail": "Email already registered"}

def test_login_and_get_me(test_client: TestClient):
    # 1. Create account and user
    acc_response = test_client.post("/accounts/", json={"name": "Login Test Account"})
    account_id = acc_response.json()["id"]
    test_client.post(
        "/users/",
        json={"email": "login@example.com", "password": "a_secure_password", "account_id": account_id}
    )

    # 2. Login to get token
    login_response = test_client.post(
        "/token",
        data={"username": "login@example.com", "password": "a_secure_password"}
    )
    assert login_response.status_code == 200
    token_data = login_response.json()
    assert "access_token" in token_data
    assert token_data["token_type"] == "bearer"
    access_token = token_data["access_token"]

    # 3. Use token to access protected endpoint
    headers = {"Authorization": f"Bearer {access_token}"}
    me_response = test_client.get("/users/me/", headers=headers)
    assert me_response.status_code == 200
    me_data = me_response.json()
    assert me_data["email"] == "login@example.com"

def test_get_me_unauthenticated(test_client: TestClient):
    response = test_client.get("/users/me/")
    # Expect 401 because we are not providing a token
    assert response.status_code == 401
    assert response.json() == {"detail": "Not authenticated"}

def test_get_me_invalid_token(test_client: TestClient):
    headers = {"Authorization": "Bearer invalidtoken"}
    response = test_client.get("/users/me/", headers=headers)
    assert response.status_code == 401
    assert response.json() == {"detail": "Could not validate credentials"}
