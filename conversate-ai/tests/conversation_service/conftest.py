import pytest
from fastapi.testclient import TestClient
from unittest.mock import MagicMock, AsyncMock
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from jose import jwt
from datetime import datetime, timedelta, timezone

# Assume these can be imported because the python path is set up correctly
from services.conversation_service.app.main import app, get_db
from services.conversation_service.app.database import Base
from services.conversation_service.app import main as conversation_main

# --- Test Database Setup ---
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"
engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@pytest.fixture(scope="function")
def db_session():
    Base.metadata.create_all(bind=engine)
    yield TestingSessionLocal()
    Base.metadata.drop_all(bind=engine)

# --- Mock Security ---
SECRET_KEY = "a_super_secret_key_for_dev"
ALGORITHM = "HS256"

def create_test_token(email: str, account_id: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=30)
    to_encode = {"sub": email, "acc": account_id, "exp": expire}
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

# --- Mock HTTP Client for LOR Service ---
@pytest.fixture(scope="function")
def mock_lor_service(monkeypatch):
    mock_http_client = MagicMock(spec=httpx.AsyncClient)
    mock_http_client.post = AsyncMock()

    # Mock the response from the LOR service
    mock_lor_response = MagicMock()
    mock_lor_response.json.return_value = {
        "response_message": "This is an intelligent AI response."
    }
    mock_http_client.post.return_value = mock_lor_response

    # Patch the client in the conversation service's main module
    monkeypatch.setattr(conversation_main, "http_client", mock_http_client)
    return mock_http_client

# --- Test Client Setup ---
@pytest.fixture(scope="function")
def test_client(db_session, mock_lor_service):
    def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    yield TestClient(app)
    del app.dependency_overrides[get_db]
