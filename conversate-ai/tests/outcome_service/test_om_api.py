from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

# We assume conftest.py provides the test_client, db_session, and mock_predictor fixtures
from services.outcome_service.app import models, schemas

ACCOUNT_ID = "om_test_account_123"

def test_log_training_episode(test_client: TestClient, db_session: Session):
    """
    Tests the data collection endpoint for logging training episodes.
    """
    episode_data = {
        "account_id": ACCOUNT_ID,
        "episode_data": {
            "turns": [
                {"t": 0, "action": "greet", "reward": 0},
                {"t": 1, "action": "offer_discount", "reward": 1}
            ]
        },
        "final_outcome": {"conversion": True, "aov": 99.99}
    }

    response = test_client.post("/episodes/log", json=episode_data)

    assert response.status_code == 201
    data = response.json()
    assert data["account_id"] == ACCOUNT_ID
    assert data["final_outcome"]["conversion"] == True

    # Verify that the episode was actually saved to the database
    db_record = db_session.query(models.TrainingEpisode).filter(models.TrainingEpisode.id == data["id"]).first()
    assert db_record is not None
    assert db_record.account_id == ACCOUNT_ID

def test_predict_next_best_action(test_client: TestClient, db_session: Session, mock_predictor):
    """
    Tests the prediction endpoint.
    """
    # 1. First, we need to create a mock active model in the database
    #    so the endpoint can find it.
    mock_model = models.UpliftModel(
        account_id=ACCOUNT_ID,
        model_type="decision_transformer",
        model_path="mock/path/model.pkl",
        is_active=True
    )
    db_session.add(mock_model)
    db_session.commit()

    # 2. Now, call the prediction API
    request_data = {
        "account_id": ACCOUNT_ID,
        "conversation_context": {"user_sentiment": 0.8},
        "potential_actions": ["offer_discount", "ask_for_email"]
    }

    response = test_client.post("/predict/next-best-action", json=request_data)

    # 3. Assert the response
    assert response.status_code == 200
    data = response.json()
    assert "predictions" in data
    assert len(data["predictions"]) > 0

    # 4. Assert that our mocks were called
    mock_predictor.load_model_from_path.assert_called_once_with("mock/path/model.pkl")
    mock_predictor.predict_next_best_action.assert_called_once()

def test_predict_action_no_active_model(test_client: TestClient):
    """
    Tests that the prediction endpoint fails gracefully if no active model is found.
    """
    request_data = {
        "account_id": "account_with_no_model",
        "conversation_context": {},
        "potential_actions": ["offer_discount"]
    }

    response = test_client.post("/predict/next-best-action", json=request_data)

    assert response.status_code == 404
    assert response.json() == {"detail": "No active model found for account account_with_no_model"}
