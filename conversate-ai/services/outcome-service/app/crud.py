from sqlalchemy.orm import Session

from . import models, schemas

def create_training_episode(db: Session, episode: schemas.TrainingEpisodeCreate):
    """
    Saves a new training episode to the database.
    """
    db_episode = models.TrainingEpisode(
        account_id=episode.account_id,
        episode_data=episode.episode_data,
        final_outcome=episode.final_outcome
    )
    db.add(db_episode)
    db.commit()
    db.refresh(db_episode)
    return db_episode

def get_active_model_for_account(db: Session, account_id: str, model_type: str):
    """
    Retrieves the latest active model for a given account and model type.
    """
    return (
        db.query(models.UpliftModel)
        .filter(
            models.UpliftModel.account_id == account_id,
            models.UpliftModel.model_type == model_type,
            models.UpliftModel.is_active == True
        )
        .order_by(models.UpliftModel.version.desc())
        .first()
    )
