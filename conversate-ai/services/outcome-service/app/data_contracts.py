from pydantic import BaseModel
from typing import List, Dict, Any, Optional

# --- Data Contracts for Training Data ---
# Based on the assumed structure for a Decision Transformer model,
# as the "CDNA-X Technical Spec" was not available.

class TimeStep(BaseModel):
    """
    Represents a single state-action-reward tuple in an episode.
    """
    state: Dict[str, Any]       # Feature vector representing the state
    action: str                 # The action taken in this timestep
    reward: float               # The reward received after this timestep

    # The "return-to-go" (sum of future rewards) can be computed from rewards
    # during data preprocessing, so it's not stored directly.

class TrainingEpisodeData(BaseModel):
    """
    Represents the full data for a single training episode.
    This corresponds to the `episode_data` field in the `TrainingEpisode` model.
    """
    timesteps: List[TimeStep]
