from fastapi import FastAPI
import logging
import time

from . import schemas
from . import retrieval_pipeline

# --- App Configuration ---
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Self-Optimizing Retrieval (SOR) Service",
    description="Provides evidence-based retrieval for the Conversate AI platform.",
    version="0.1.0",
)

# --- Lifespan Management (for loading models) ---
@app.on_event("startup")
async def startup_event():
    logger.info("Starting SOR Service...")
    retrieval_pipeline.load_models()
    logger.info("SOR Service started.")

# --- API Endpoints ---

@app.get("/")
def read_root():
    return {"service": "SOR Service", "status": "ok"}

@app.get("/health")
def health_check():
    return {"status": "ok", "models_loaded": retrieval_pipeline.are_models_loaded()}

@app.post("/search", response_model=schemas.EvidenceBundle)
async def search(query: schemas.SearchQuery):
    """
    Performs semantic search and returns an evidence bundle.
    """
    start_time = time.time()
    logger.info(f"Received search query: '{query.query}'")

    # This is a placeholder for the full retrieval pipeline.
    # In a real implementation, this would call the different layers
    # of the retrieval process (GraphRAG, RAPTOR, etc.).
    citations, verifications = retrieval_pipeline.search(query.query, query.top_k)

    # Placeholder confidence score
    confidence = sum(c.score for c in citations) / len(citations) if citations else 0.0

    end_time = time.time()
    processing_time_ms = (end_time - start_time) * 1000

    return schemas.EvidenceBundle(
        citations=citations,
        confidence=confidence,
        verifications=verifications,
        processing_time_ms=processing_time_ms,
    )
