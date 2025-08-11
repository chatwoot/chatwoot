import logging
from sentence_transformers import SentenceTransformer
from sqlalchemy.orm import Session

from . import models, schemas

# --- Globals ---
logger = logging.getLogger(__name__)
embedding_model = SentenceTransformer('all-MiniLM-L6-v2')
logger.info("SentenceTransformer model 'all-MiniLM-L6-v2' loaded.")

# --- Document Processing and Indexing ---

def _chunk_text(text: str, chunk_size: int = 512, overlap: int = 50) -> list[str]:
    tokens = text.split()
    chunks = []
    for i in range(0, len(tokens), chunk_size - overlap):
        chunks.append(" ".join(tokens[i:i + chunk_size]))
    return chunks

def process_and_index_document(db: Session, doc_name: str, doc_content: str, account_id: str, source_url: str = None):
    logger.info(f"Processing document: {doc_name}")

    db_document = models.Document(
        name=doc_name,
        account_id=account_id,
        source_url=source_url
    )
    db.add(db_document)
    db.commit()
    db.refresh(db_document)

    chunks = _chunk_text(doc_content)
    embeddings = embedding_model.encode(chunks)

    for i, chunk_content in enumerate(chunks):
        db_chunk = models.DocumentChunk(
            document_id=db_document.id,
            content=chunk_content,
            embedding=embeddings[i]
        )
        db.add(db_chunk)

    db.commit()
    logger.info(f"Successfully indexed document {db_document.id} with {len(chunks)} chunks.")
    return db_document

# --- Semantic Search Logic ---

def search(query: str, top_k: int, db: Session, account_id: str):
    """
    Performs a semantic search for a given query and account.
    """
    logger.info(f"Performing semantic search for account '{account_id}' with query: '{query}'")

    # 1. Generate an embedding for the user's query
    query_embedding = embedding_model.encode(query)

    # 2. Perform vector similarity search in the database
    # We use the l2_distance operator (<->) provided by pgvector.
    # We also join with the documents table to filter by account_id.
    similar_chunks = (
        db.query(models.DocumentChunk)
        .join(models.Document)
        .filter(models.Document.account_id == account_id)
        .order_by(models.DocumentChunk.embedding.l2_distance(query_embedding))
        .limit(top_k)
        .all()
    )

    logger.info(f"Found {len(similar_chunks)} similar document chunks.")

    # 3. Format the results into an EvidenceBundle (or at least the citations part)
    citations = []
    for chunk in similar_chunks:
        # The distance is not directly a confidence score, but we can use it to create one.
        # A lower distance means higher similarity. We'll do a simple inversion for a score.
        # This is a simplification; a real system might use a more robust scoring method.
        score = 1 - chunk.embedding.l2_distance(query_embedding)
        citations.append(
            schemas.Citation(
                doc_id=chunk.document_id,
                content=chunk.content,
                score=score
            )
        )

    # Placeholder for the Self-RAG verification step
    verifications = [
        schemas.Verification(check_name="retrieval_successful", status=True, details=f"Found {len(citations)} results.")
    ]

    return citations, verifications
