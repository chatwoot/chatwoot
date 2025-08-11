from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

# --- Message Schemas ---

class MessageBase(BaseModel):
    content: str

class MessageCreate(MessageBase):
    sender_id: str
    sender_type: str # 'user' or 'contact'

class Message(MessageBase):
    id: str
    conversation_id: str
    sender_id: str
    sender_type: str
    created_at: datetime

    class Config:
        orm_mode = True

# --- Conversation Schemas ---

class ConversationBase(BaseModel):
    status: Optional[str] = 'open'

class ConversationCreate(ConversationBase):
    account_id: str
    participant_ids: List[str] # List of contact IDs

class Conversation(ConversationBase):
    id: str
    account_id: str
    last_activity_at: datetime
    created_at: datetime
    messages: List[Message] = []
    # participant_ids would also be here, loaded from the association

    class Config:
        orm_mode = True
