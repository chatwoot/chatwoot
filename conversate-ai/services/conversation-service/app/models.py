from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, Table
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

from .database import Base

# Association Table for Conversation Participants (Contacts)
conversation_participants = Table(
    "conversation_participants",
    Base.metadata,
    Column("conversation_id", String, ForeignKey("conversations.id"), primary_key=True),
    Column("contact_id", String, index=True, primary_key=True), # This ID comes from the Contact Service
)

class Conversation(Base):
    __tablename__ = "conversations"

    id = Column(String, primary_key=True, default=lambda: f"conv_{uuid.uuid4().hex}")
    account_id = Column(String, index=True, nullable=False) # Foreign key to Account in Identity Service
    status = Column(String, index=True, default="open") # open, resolved, snoozed

    last_activity_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    messages = relationship("Message", back_populates="conversation", cascade="all, delete-orphan")

    # This defines the many-to-many relationship to contacts (which live in another service)
    # We only store the IDs here.
    participant_ids = relationship("Contact", secondary=conversation_participants, viewonly=True)


class Message(Base):
    __tablename__ = "messages"

    id = Column(String, primary_key=True, default=lambda: f"msg_{uuid.uuid4().hex}")
    conversation_id = Column(String, ForeignKey("conversations.id"), nullable=False)

    # The sender can be a User from the Identity Service or a Contact from the Contact Service
    sender_id = Column(String, index=True, nullable=False)
    sender_type = Column(String, nullable=False) # 'user' or 'contact'

    content = Column(Text, nullable=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now())

    conversation = relationship("Conversation", back_populates="messages")


# This is a simple model to represent the contact side of the M2M relationship
# It is not the full Contact model, which lives in the Contact service.
class Contact(Base):
    __tablename__ = "contacts_view" # This isn't a real table, just for the relationship
    contact_id = Column(String, primary_key=True)
