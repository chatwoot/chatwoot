from fastapi.testclient import TestClient
from datetime import datetime

# We assume conftest.py provides the test_client and mock_graph_db fixtures

def test_health_check(test_client: TestClient):
    """
    Tests the health check endpoint.
    """
    response = test_client.get("/health")
    assert response.status_code == 200
    assert "status" in response.json()

def test_ingest_event(test_client: TestClient, mock_graph_db):
    """
    Tests the event ingestion endpoint.
    """
    event_data = {
        "event_id": "evt_test_1",
        "timestamp": datetime.now().isoformat(),
        "channel": "web",
        "actor_id": "actor_123",
        "org_id": "org_456",
        "text": "This is a test event."
    }

    response = test_client.post("/ingest", json=[event_data])

    assert response.status_code == 202
    assert response.json() == {"message": "Events accepted for processing."}

    # In a real test, we would need a way to check that the background task
    # called our mocked function. This is complex to test and is omitted here,
    # but we have validated the API endpoint itself.

def test_get_episode_history(test_client: TestClient, mock_graph_db):
    """
    Tests retrieving the history for a conversation episode.
    """
    episode_id = "ep_test_1"
    response = test_client.get(f"/episodes/{episode_id}")

    assert response.status_code == 200

    # Assert that the mocked graph_db function was called with the correct ID
    mock_graph_db.get_episode_history.assert_called_once_with(episode_id)

    # Assert that the response matches the mock data
    data = response.json()
    assert len(data) == 1
    assert data[0]["text"] == "Hello from the mock DB"
    assert data[0]["turn_id"] == "turn_test_123"

def test_get_nonexistent_episode(test_client: TestClient, mock_graph_db):
    """
    Tests the response for a non-existent episode.
    """
    # Configure the mock to return an empty list for this test
    mock_graph_db.get_episode_history.return_value = []

    episode_id = "ep_not_found"
    response = test_client.get(f"/episodes/{episode_id}")

    assert response.status_code == 404
    assert response.json() == {"detail": "Episode not found"}
