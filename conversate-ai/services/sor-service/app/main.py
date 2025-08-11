from fastapi import Depends, FastAPI, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List

from . import retrieval_pipeline, schemas, models
from .database import SessionLocal, engine
from .security import get_current_user, UserInDB

# Create tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Self-Optimizing Retrieval (SOR) Service",
    description="Provides evidence-based retrieval for the Conversate AI platform.",
    version="0.1.0",
)

# --- Dependency ---
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# --- API Endpoints ---

@app.get("/")
def read_root():
    return {"service": "SOR Service", "status": "ok"}

@app.post("/documents/", status_code=202)
async def create_document_for_indexing(
    doc_name: str,
    doc_content: str,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Accepts a new document and adds it to a background queue for processing and indexing.
    """
    background_tasks.add_task(
        retrieval_pipeline.process_and_index_document,
        db=db,
        doc_name=doc_name,
        doc_content=doc_content,
        account_id=current_user.account_id
    )
    return {"message": "Document accepted for indexing."}


@app.post("/search", response_model=schemas.EvidenceBundle)
async def search(
    query: schemas.SearchQuery,
    db: Session = Depends(get_db),
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Performs semantic search and returns an evidence bundle.
    """
    citations, verifications = retrieval_pipeline.search(
        query=query.query,
        top_k=query.top_k,
        db=db,
        account_id=current_user.account_id
    )

    # Placeholder confidence score
    confidence = sum(c.score for c in citations) / len(citations) if citations else 0.0

    return schemas.EvidenceBundle(
        citations=citations,
        confidence=confidence,
        verifications=verifications,
        processing_time_ms=0 # Placeholder
    )
