from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid
from pgvector.sqlalchemy import Vector

from .database import Base

class Document(Base):
    __tablename__ = "documents"

    id = Column(String, primary_key=True, default=lambda: f"doc_{uuid.uuid4().hex}")
    account_id = Column(String, index=True, nullable=False)
    source_url = Column(String, nullable=True)
    name = Column(String, nullable=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now())

    chunks = relationship("DocumentChunk", back_populates="document", cascade="all, delete-orphan")


class DocumentChunk(Base):
    __tablename__ = "document_chunks"

    id = Column(Integer, primary_key=True, index=True)
    document_id = Column(String, ForeignKey("documents.id"), nullable=False)

    content = Column(Text, nullable=False)

    # The embedding vector. The dimension (384) should match the embedding model.
    embedding = Column(Vector(384))

    document = relationship("Document", back_populates="chunks")
