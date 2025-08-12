from sqlalchemy import Column, Integer, String, JSON, DateTime, Float
from sqlalchemy.sql import func
import uuid

from .database import Base

class TrainingEpisode(Base):
    """
    Stores a complete conversational episode with its final outcome,
    used as training data for the Outcome Model.
    """
    __tablename__ = "training_episodes"

    id = Column(String, primary_key=True, default=lambda: f"ep_train_{uuid.uuid4().hex}")
    account_id = Column(String, index=True, nullable=False)

    # Stores the list of turns, actions, features, and rewards
    # as described in the CDNA-X "Training data contract"
    episode_data = Column(JSON, nullable=False)

    # The final outcome(s) of the conversation
    final_outcome = Column(JSON, nullable=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now())


class UpliftModel(Base):
    """
    Stores metadata about a trained uplift or decision transformer model.
    """
    __tablename__ = "uplift_models"

    id = Column(String, primary_key=True, default=lambda: f"model_{uuid.uuid4().hex}")
    account_id = Column(String, index=True, nullable=False)
    model_type = Column(String, nullable=False) # e.g., 'decision_transformer', 'uplift_forest'

    # Path to the serialized model file (e.g., in a cloud storage bucket)
    model_path = Column(String, nullable=False)

    version = Column(Integer, default=1)
    performance_metrics = Column(JSON, nullable=True) # e.g., accuracy, precision, recall
    is_active = Column(Integer, default=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
