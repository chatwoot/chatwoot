import pytest
from fastapi.testclient import TestClient
from unittest.mock import MagicMock, AsyncMock

# To make this test runnable, we would need to adjust the python path
# to include the services directory. For this simulation, we assume it's available.
from services.lor_service.app.main import app
from services.lor_service.app import runtime

@pytest.fixture(scope="function")
def mock_clients(monkeypatch):
    """
    Mocks the HTTP and LLM clients used by the Conversation Runtime.
    """
    # Mock httpx client
    mock_http_client = MagicMock(spec=httpx.AsyncClient)
    # The post and get methods must be async mocks
    mock_http_client.post = AsyncMock()
    mock_http_client.get = AsyncMock()

    # Mock the SOR service response
    mock_sor_response = MagicMock()
    mock_sor_response.json.return_value = {
        "citations": [{"id": "kb://reschedule_policy", "content": "Our policy allows rescheduling."}],
        "confidence": 0.9
    }
    mock_http_client.post.return_value = mock_sor_response

    # Mock the OpenAI client
    mock_llm_client = MagicMock()
    mock_choice = MagicMock()
    mock_choice.message.content = "This is a mock LLM response."
    mock_llm_response = MagicMock()
    mock_llm_response.choices = [mock_choice]
    mock_llm_client.chat.completions.create.return_value = mock_llm_response

    # Apply the mocks to the runtime module
    monkeypatch.setattr(runtime, "http_client", mock_http_client)
    monkeypatch.setattr(runtime, "llm_client", mock_llm_client)

    return mock_http_client, mock_llm_client


@pytest.fixture(scope="function")
def test_client(mock_clients):
    """
    Creates a test client for the API.
    The mock_clients fixture ensures that external calls are mocked.
    """
    yield TestClient(app)
