from fastapi import Depends, FastAPI, HTTPException
from sqlalchemy.orm import Session
from typing import List

from . import crud, models, schemas
from .database import SessionLocal, engine

models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Outcome Model (OM) Service",
    description="Manages ML model training and prediction for business outcomes.",
    version="0.1.0",
)

# --- Dependency ---
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# --- API Endpoints ---

@app.get("/")
def read_root():
    return {"service": "Outcome Model Service", "status": "ok"}

@app.post("/episodes/log", response_model=schemas.TrainingEpisode, status_code=201)
def log_training_episode(
    episode: schemas.TrainingEpisodeCreate,
    db: Session = Depends(get_db)
):
    """
    Receives and stores a completed conversation episode for future model training.
    This endpoint would be called by other services (like the Conversation Service)
    at the end of a conversation.
    """
    # In a real system, this endpoint should be secured, probably with a
    # service-to-service authentication mechanism (e.g., API key, mutual TLS).
    # For now, we'll leave it open for simplicity.

    return crud.create_training_episode(db=db, episode=episode)

from . import predictor

@app.post("/predict/next-best-action", response_model=schemas.PredictionResponse)
def predict_next_best_action(
    request: schemas.PredictionRequest,
    db: Session = Depends(get_db)
):
    """
    Predicts the expected uplift for a list of potential conversational actions.
    """
    # 1. Find the active model for this account
    # For now, we'll hardcode the model type. In a real system, this might be more dynamic.
    active_model_record = crud.get_active_model_for_account(db, account_id=request.account_id, model_type="decision_transformer")

    if not active_model_record:
        raise HTTPException(status_code=404, detail=f"No active model found for account {request.account_id}")

    # 2. Load the model (simulation)
    model = predictor.load_model_from_path(active_model_record.model_path)

    # 3. Get predictions
    predictions = predictor.predict_next_best_action(
        model=model,
        context=request.conversation_context,
        potential_actions=request.potential_actions
    )

    return predictions
