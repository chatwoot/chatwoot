from sqlalchemy import Column, Integer, String, JSON, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

from .database import Base

class Contact(Base):
    __tablename__ = "contacts"

    id = Column(String, primary_key=True, default=lambda: f"contact_{uuid.uuid4().hex}")
    account_id = Column(String, index=True, nullable=False) # Foreign key to Account in Identity Service
    email = Column(String, index=True, nullable=True)
    phone_number = Column(String, index=True, nullable=True)
    first_name = Column(String, nullable=True)
    last_name = Column(String, nullable=True)

    additional_attributes = Column(JSON, nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    custom_attributes = relationship("CustomAttribute", back_populates="contact", cascade="all, delete-orphan")


class CustomAttribute(Base):
    __tablename__ = "custom_attributes"

    id = Column(Integer, primary_key=True, index=True)
    contact_id = Column(String, ForeignKey("contacts.id"), nullable=False)
    name = Column(String, index=True, nullable=False)
    value = Column(String, nullable=False)

    contact = relationship("Contact", back_populates="custom_attributes")
