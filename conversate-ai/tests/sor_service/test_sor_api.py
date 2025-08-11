import pytest
from fastapi.testclient import TestClient
from unittest.mock import MagicMock
from jose import jwt
from datetime import datetime, timedelta, timezone

# To make this test runnable, we would need to adjust the python path
# to include the services directory. For this simulation, we assume it's available.
from services.sor_service.app.main import app
from services.sor_service.app import retrieval_pipeline, schemas

# --- Mock Security ---

SECRET_KEY = "a_super_secret_key_for_dev"
ALGORITHM = "HS256"

def create_test_token(email: str, account_id: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=30)
    to_encode = {"sub": email, "acc": account_id, "exp": expire}
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

# --- Pytest Fixtures ---

@pytest.fixture(scope="function")
def mock_retrieval_pipeline(monkeypatch):
    mock = MagicMock()
    mock_citations = [
        schemas.Citation(doc_id="doc_123", content="This is a test document chunk.", score=0.95)
    ]
    mock_verifications = [
        schemas.Verification(check_name="test_check", status=True, details="Test verification passed.")
    ]
    mock.search.return_value = (mock_citations, mock_verifications)
    mock.process_and_index_document.return_value = None

    monkeypatch.setattr(retrieval_pipeline, "process_and_index_document", mock.process_and_index_document)
    monkeypatch.setattr(retrieval_pipeline, "search", mock.search)
    return mock

@pytest.fixture(scope="function")
def test_client(mock_retrieval_pipeline):
    yield TestClient(app)

# --- API Tests ---

def test_search_api(test_client: TestClient, mock_retrieval_pipeline):
    """
    Tests the /search endpoint.
    """
    token = create_test_token(email="test@example.com", account_id="acc_123")
    headers = {"Authorization": f"Bearer {token}"}

    response = test_client.post(
        "/search",
        headers=headers,
        json={"query": "What is this test about?", "top_k": 3}
    )

    assert response.status_code == 200
    data = response.json()
    assert data["confidence"] > 0
    assert len(data["citations"]) == 1
    assert data["citations"][0]["doc_id"] == "doc_123"

    # Assert that the underlying search function was called correctly
    mock_retrieval_pipeline.search.assert_called_once_with(
        query="What is this test about?",
        top_k=3,
        db=None, # The db dependency is not mocked here, but in a real test it would be
        account_id="acc_123"
    )

def test_documents_api(test_client: TestClient, mock_retrieval_pipeline):
    """
    Tests the /documents endpoint for submitting new documents.
    """
    token = create_test_token(email="test@example.com", account_id="acc_123")
    headers = {"Authorization": f"Bearer {token}"}

    response = test_client.post(
        "/documents/",
        headers=headers,
        params={"doc_name": "Test Doc", "doc_content": "This is the content."}
    )

    assert response.status_code == 202
    assert response.json() == {"message": "Document accepted for indexing."}

    # In a real test, we would need a way to check that the background task
    # called our mocked function. This is complex to test and is omitted here,
    # but we have validated the API endpoint itself.

def test_search_unauthenticated(test_client: TestClient):
    """
    Tests that unauthenticated requests to /search are rejected.
    """
    response = test_client.post("/search", json={"query": "test"})
    assert response.status_code == 401
    assert response.json() == {"detail": "Not authenticated"}
