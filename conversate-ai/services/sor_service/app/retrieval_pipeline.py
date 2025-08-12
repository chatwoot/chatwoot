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

def run_self_rag_pipeline(query: str, top_k: int, db: Session, account_id: str) -> schemas.EvidenceBundle:
    """
    Implements the Self-Optimizing Retrieval (SOR) pipeline v1.
    This includes a trigger policy and a self-critique step.
    """
    start_time = time.time()
    logger.info(f"Running Self-RAG pipeline for account '{account_id}' with query: '{query}'")

    # 1. Self-RAG Trigger Policy (Mock Implementation)
    # Decides if retrieval is necessary. Here, we use a simple keyword-based rule.
    # A real implementation would use a small, fine-tuned model.
    keywords_that_trigger_retrieval = ["how", "what", "who", "when", "where", "why", "price", "cost"]
    should_retrieve = any(keyword in query.lower() for keyword in keywords_that_trigger_retrieval)

    if not should_retrieve:
        logger.info("Self-RAG trigger: Retrieval not necessary.")
        return schemas.EvidenceBundle(
            citations=[],
            confidence=0.9, # High confidence in not needing to retrieve
            verifications=[
                schemas.Verification(check_name="retrieval_trigger", status=False, details="Query does not require external knowledge.")
            ],
            processing_time_ms=(time.time() - start_time) * 1000
        )

    logger.info("Self-RAG trigger: Retrieval required.")

    # 2. Perform Semantic Search (the existing RAG logic)
    query_embedding = embedding_model.encode(query)
    similar_chunks = (
        db.query(models.DocumentChunk)
        .join(models.Document)
        .filter(models.Document.account_id == account_id)
        .order_by(models.DocumentChunk.embedding.l2_distance(query_embedding))
        .limit(top_k)
        .all()
    )
    logger.info(f"Found {len(similar_chunks)} similar document chunks.")

    if not similar_chunks:
        return schemas.EvidenceBundle(
            citations=[],
            confidence=0.2, # Low confidence because we found nothing
            verifications=[
                schemas.Verification(check_name="retrieval_trigger", status=True, details="Retrieval was triggered."),
                schemas.Verification(check_name="retrieval_successful", status=False, details="No relevant documents found.")
            ],
            processing_time_ms=(time.time() - start_time) * 1000
        )

    # 3. Self-Critique Step (Mock Implementation)
    # Filters and verifies the retrieved chunks. A real implementation would use an LLM.
    verifications = [
        schemas.Verification(check_name="retrieval_trigger", status=True, details="Retrieval was triggered."),
        schemas.Verification(check_name="retrieval_successful", status=True, details=f"Found {len(similar_chunks)} candidate chunks.")
    ]

    final_citations = []
    total_score = 0
    for chunk in similar_chunks:
        # Mock relevance check: does the chunk contain any query terms?
        is_relevant = any(term in chunk.content.lower() for term in query.lower().split())
        if is_relevant:
            score = 1 - chunk.embedding.l2_distance(query_embedding)
            final_citations.append(
                schemas.Citation(
                    doc_id=chunk.document_id,
                    content=chunk.content,
                    score=score
                )
            )
            total_score += score

    verifications.append(
        schemas.Verification(
            check_name="relevance_critique",
            status=True,
            details=f"Kept {len(final_citations)} of {len(similar_chunks)} chunks after relevance check."
        )
    )

    # 4. Assemble the final EvidenceBundle
    confidence = (total_score / len(final_citations)) if final_citations else 0.1

    evidence = schemas.EvidenceBundle(
        citations=final_citations,
        confidence=confidence,
        verifications=verifications,
        processing_time_ms=(time.time() - start_time) * 1000
    )

    logger.info(f"Self-RAG pipeline complete. Confidence: {confidence:.2f}")
    return evidence
