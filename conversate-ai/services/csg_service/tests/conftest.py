import pytest
from fastapi.testclient import TestClient
from unittest.mock import MagicMock

from app.main import app
from app import graph_db

@pytest.fixture(scope="function")
def mock_graph_db(monkeypatch):
    """
    Mocks the entire graph_db module to prevent actual DB calls.
    """
    mock = MagicMock()
    mock.process_event.return_value = True
    mock.get_episode_history.return_value = [
        {
            "turn_id": "turn_test_123",
            "text": "Hello from the mock DB",
            "timestamp": "2025-01-01T12:00:00Z",
            "channel": "web"
        }
    ]

    monkeypatch.setattr(graph_db, "process_event", mock.process_event)
    monkeypatch.setattr(graph_db, "get_episode_history", mock.get_episode_history)

    return mock

@pytest.fixture(scope="function")
def test_client(mock_graph_db):
    """
    Creates a test client for the API.
    The mock_graph_db fixture ensures that DB calls are mocked.
    """
    yield TestClient(app)
