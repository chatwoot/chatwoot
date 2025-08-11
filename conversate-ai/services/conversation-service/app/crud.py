from sqlalchemy.orm import Session

from . import models, schemas

# --- Conversation CRUD ---

def get_conversation(db: Session, conversation_id: str):
    return db.query(models.Conversation).filter(models.Conversation.id == conversation_id).first()

def get_conversations_by_account(db: Session, account_id: str, skip: int = 0, limit: int = 100):
    return db.query(models.Conversation).filter(models.Conversation.account_id == account_id).offset(skip).limit(limit).all()

def create_conversation(db: Session, conversation: schemas.ConversationCreate):
    db_conversation = models.Conversation(
        account_id=conversation.account_id,
        status=conversation.status
    )
    # Note: Handling the many-to-many participant_ids would be more complex.
    # This is a simplified version for now.
    db.add(db_conversation)
    db.commit()
    db.refresh(db_conversation)
    return db_conversation

# --- Message CRUD ---

def get_messages_for_conversation(db: Session, conversation_id: str, skip: int = 0, limit: int = 100):
    return db.query(models.Message).filter(models.Message.conversation_id == conversation_id).order_by(models.Message.created_at.asc()).offset(skip).limit(limit).all()

def create_message_in_conversation(db: Session, message: schemas.MessageCreate, conversation_id: str):
    db_message = models.Message(
        **message.dict(),
        conversation_id=conversation_id
    )
    db.add(db_message)
    # We also need to update the last_activity_at of the parent conversation
    db_conversation = get_conversation(db, conversation_id)
    db_conversation.last_activity_at = db_message.created_at
    db.commit()
    db.refresh(db_message)
    return db_message
