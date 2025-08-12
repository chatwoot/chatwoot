import logging
import pandas as pd
from sqlalchemy.orm import Session
import time
import os
import json
from typing import List, Dict, Any

import numpy as np
import tensorflow as tf
from pydantic import ValidationError

from . import models, crud
from .data_contracts import TrainingEpisodeData
from .decision_transformer import DecisionTransformer

logger = logging.getLogger(__name__)

# --- Constants ---
# These would typically come from a config file
STATE_DIM = 10  # Example dimension for state features
MAX_EP_LEN = 100 # Max length of a conversational episode
CONTEXT_LEN = 20 # The context length the model uses for prediction

# --- Data Preprocessing ---

def _get_action_mappings(episodes: List[models.TrainingEpisode]):
    """Creates mappings from unique action strings to integers and back."""
    all_actions = set()
    for episode in episodes:
        try:
            episode_data = TrainingEpisodeData.parse_obj(episode.episode_data)
            for timestep in episode_data.timesteps:
                all_actions.add(timestep.action)
        except ValidationError:
            logger.warning(f"Skipping episode {episode.id} due to validation error.")
            continue

    action_to_id = {action: i for i, action in enumerate(sorted(list(all_actions)))}
    id_to_action = {i: action for action, i in action_to_id.items()}
    return action_to_id, id_to_action

def _prepare_data_for_transformer(
    episodes: List[models.TrainingEpisode],
    action_to_id: Dict[str, int],
    state_dim: int,
    max_len: int
):
    """
    Prepares raw episode data for the Decision Transformer model.
    - Vectorizes states
    - Calculates returns-to-go
    - Tokenizes actions
    - Pads all sequences to max_len
    """
    all_states, all_actions, all_returns, all_timesteps, all_masks = [], [], [], [], []

    for episode in episodes:
        try:
            episode_data = TrainingEpisodeData.parse_obj(episode.episode_data)
        except ValidationError:
            continue # Skip episodes that don't match our contract

        states, actions, rewards = [], [], []
        for ts in episode_data.timesteps:
            # A real implementation would have a more robust feature extraction
            # Here we just create a placeholder vector from the state dict values
            state_vector = list(ts.state.values()) if isinstance(ts.state, dict) else [ts.state]
            state_vector = [float(v) for v in state_vector if isinstance(v, (int, float))]
            state_vector += [0.0] * (state_dim - len(state_vector))
            states.append(state_vector[:state_dim])
            actions.append(action_to_id.get(ts.action, -1)) # -1 for unknown actions
            rewards.append(ts.reward)

        # Calculate returns-to-go
        returns = np.cumsum(rewards[::-1])[::-1]

        # Pad or truncate sequences
        seq_len = len(states)
        if seq_len == 0:
            continue

        padding_len = max_len - seq_len

        # States
        states = np.array(states, dtype=np.float32)
        states = np.pad(states, ((0, padding_len), (0, 0)), 'constant') if padding_len > 0 else states[:max_len]

        # Actions
        actions = np.array(actions, dtype=np.int32)
        actions = np.pad(actions, (0, padding_len), 'constant') if padding_len > 0 else actions[:max_len]

        # Returns
        returns = np.array(returns, dtype=np.float32).reshape(-1, 1)
        returns = np.pad(returns, ((0, padding_len), (0, 0)), 'constant') if padding_len > 0 else returns[:max_len]

        # Timesteps
        timesteps = np.arange(seq_len)
        timesteps = np.pad(timesteps, (0, padding_len), 'constant') if padding_len > 0 else timesteps[:max_len]

        # Masks (to ignore padding)
        mask = np.concatenate([np.ones(seq_len), np.zeros(padding_len)]) if padding_len >= 0 else np.ones(max_len)


        all_states.append(states)
        all_actions.append(actions)
        all_returns.append(returns)
        all_timesteps.append(timesteps)
        all_masks.append(mask)

    if not all_states:
        return [np.array([]) for _ in range(5)]

    return (
        np.array(all_states),
        np.array(all_actions),
        np.array(all_returns),
        np.array(all_timesteps),
        np.array(all_masks),
    )


# --- Real ML Model Training Functions ---

def train_decision_transformer(
    episodes: List[models.TrainingEpisode],
    state_dim: int,
    max_ep_len: int
):
    """
    Trains a Decision Transformer model.
    """
    logger.info("Starting training for Decision Transformer...")
    if not episodes:
        logger.warning("No episodes to train on.")
        return None

    # 1. Create action mappings
    action_to_id, id_to_action = _get_action_mappings(episodes)
    action_dim = len(action_to_id)
    if action_dim == 0:
        logger.warning("No valid actions found in training data.")
        return None

    # 2. Prepare data
    states, actions, returns, timesteps, masks = _prepare_data_for_transformer(
        episodes, action_to_id, state_dim, max_ep_len
    )

    if states.size == 0 or states.shape[0] == 0:
        logger.warning("No valid data could be prepared for training.")
        return None

    logger.info(f"Training with {states.shape[0]} episodes. Action space size: {action_dim}")

    # 3. Instantiate and compile the model
    model = DecisionTransformer(
        state_dim=state_dim,
        action_dim=action_dim,
        max_ep_len=max_ep_len,
    )

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-4),
        loss={
            "output_1": tf.keras.losses.MeanSquaredError(), # State loss
            "output_2": tf.keras.losses.SparseCategoricalCrossentropy(), # Action loss
            "output_3": tf.keras.losses.MeanSquaredError(), # Return loss
        },
    )

    # 4. Train the model
    model.fit(
        x=(states[:, :-1], actions[:, :-1], returns[:, :-1], timesteps[:, :-1]),
        y=(states[:, 1:], actions[:, 1:], returns[:, 1:]),
        sample_weight=masks[:, 1:],
        epochs=1, # Keep low for demonstration purposes
        batch_size=64,
        verbose=1,
    )

    # 5. Save the model and mappings
    timestamp = int(time.time())
    model_path = f"models/decision_transformer/v_{timestamp}"
    mappings_path = os.path.join(model_path, "action_mappings.json")

    os.makedirs(model_path, exist_ok=True)
    model.save(model_path)
    with open(mappings_path, "w") as f:
        json.dump({"action_to_id": action_to_id, "id_to_action": id_to_action}, f)

    logger.info(f"Decision Transformer training complete. Model saved to {model_path}")
    return model_path

def train_uplift_model(df: pd.DataFrame):
    """
    Simulates training an Uplift Model. (This remains a placeholder)
    """
    logger.info("Starting training for Uplift Model...")
    logger.info(f"Training with {len(df)} episodes.")
    time.sleep(3)

    model_path = f"models/uplift_model/v_{int(time.time())}.joblib"
    os.makedirs(os.path.dirname(model_path), exist_ok=True)
    with open(model_path, "w") as f:
        f.write("This is a mock scikit-learn model file.")

    logger.info(f"Uplift Model training complete. Model saved to {model_path}")
    return model_path

# --- Main Training Pipeline ---

def run_training_pipeline(db: Session, account_id: str):
    """
    Executes the full ML training pipeline for a given account.
    """
    logger.info(f"Starting training pipeline for account: {account_id}")

    # 1. Fetch training data from the database
    episodes = db.query(models.TrainingEpisode).filter(models.TrainingEpisode.account_id == account_id).all()
    if not episodes:
        logger.warning("No training episodes found. Skipping pipeline.")
        return {}

    # 2. Train the Decision Transformer model
    dt_model_path = train_decision_transformer(
        episodes,
        state_dim=STATE_DIM,
        max_ep_len=MAX_EP_LEN
    )

    # 3. Train the Uplift model (placeholder)
    episode_data = [e.episode_data for e in episodes]
    df = pd.DataFrame(episode_data)
    uplift_model_path = train_uplift_model(df)

    # 4. Save metadata about the new models to the database
    logger.info("Saving new model metadata to the database...")
    if dt_model_path:
        crud.create_uplift_model(db, account_id=account_id, model_type="decision_transformer", model_path=dt_model_path)
    if uplift_model_path:
        crud.create_uplift_model(db, account_id=account_id, model_type="uplift_forest", model_path=uplift_model_path)

    logger.info(f"Training pipeline for account {account_id} complete.")
    return {"decision_transformer_path": dt_model_path, "uplift_model_path": uplift_model_path}
