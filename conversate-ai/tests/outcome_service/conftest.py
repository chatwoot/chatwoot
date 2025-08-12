import pytest
from fastapi.testclient import TestClient
from unittest.mock import MagicMock
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

# Assume these can be imported because the python path is set up correctly
from services.outcome_service.app.main import app, get_db
from services.outcome_service.app.database import Base
from services.outcome_service.app import predictor

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
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)

# --- Mock Predictor Module ---
@pytest.fixture(scope="function")
def mock_predictor(monkeypatch):
    """
    Mocks the predictor module to prevent loading actual ML models.
    """
    mock = MagicMock()
    mock.load_model_from_path.return_value = {"path": "mock/model.pkl"}
    mock.predict_next_best_action.return_value = {
        "predictions": [{"action": "test_action", "expected_uplift": {"conversion": 0.1}}]
    }

    monkeypatch.setattr(predictor, "load_model_from_path", mock.load_model_from_path)
    monkeypatch.setattr(predictor, "predict_next_best_action", mock.predict_next_best_action)

    return mock

# --- Test Client Setup ---
@pytest.fixture(scope="function")
def test_client(db_session, mock_predictor):
    def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    yield TestClient(app)
    del app.dependency_overrides[get_db]
