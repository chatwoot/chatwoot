from pydantic import BaseModel
from typing import List, Dict, Any

# --- Pydantic Schemas for API Data Contracts ---

class TrainingEpisodeCreate(BaseModel):
    account_id: str
    episode_data: Dict[str, Any] # This would match the "Training data contract" from CDNA-X
    final_outcome: Dict[str, Any]

class TrainingEpisode(TrainingEpisodeCreate):
    id: str

    class Config:
        orm_mode = True

# --- Prediction API Schemas ---

class PredictionRequest(BaseModel):
    account_id: str
    conversation_context: Dict[str, Any]
    potential_actions: List[str]

class ActionPrediction(BaseModel):
    action: str
    expected_uplift: Dict[str, float] # e.g., {"conversion": 0.05, "csat": 0.2}

class PredictionResponse(BaseModel):
    predictions: List[ActionPrediction]

class UpliftModel(BaseModel):
    id: str
    account_id: str
    model_type: str
    model_path: str
    version: int
    is_active: bool

    class Config:
        orm_mode = True
