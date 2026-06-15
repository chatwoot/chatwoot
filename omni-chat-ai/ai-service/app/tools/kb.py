"""Knowledge-base RAG tool (Qdrant + local embeddings).

Operators upload product/FAQ/warranty docs in the admin panel; we chunk and index them in
Qdrant using local fastembed embeddings (no extra API key, multilingual-capable). Agents call
``kb_search`` to ground answers. Everything degrades gracefully: if the store is empty or
unreachable, search returns nothing and the agent escalates rather than inventing facts.
"""
from __future__ import annotations

from ..config import settings

COLLECTION = "omni_kb"
_client = None


def _chunk(text: str, size: int = 600, overlap: int = 80) -> list[str]:
    """Split text into overlapping character windows on paragraph-ish boundaries."""
    text = text.strip()
    if len(text) <= size:
        return [text] if text else []
    chunks: list[str] = []
    start = 0
    n = len(text)
    while start < n:
        end = min(start + size, n)
        # Prefer to break on a newline/space near the window end, but only if that still leaves
        # a reasonably full chunk — otherwise we'd snap back and never make progress.
        if end < n:
            brk = text.rfind("\n", start, end)
            if brk == -1:
                brk = text.rfind(" ", start, end)
            if brk > start + overlap:
                end = brk
        chunk = text[start:end].strip()
        if chunk:
            chunks.append(chunk)
        if end >= n:
            break
        start = end - overlap  # guaranteed > start, since end > start + overlap here
    return chunks


def _get_client():
    """Lazily build an AsyncQdrantClient with the configured embedding model."""
    global _client
    if _client is None:
        from qdrant_client import AsyncQdrantClient

        _client = AsyncQdrantClient(url=settings.qdrant_url)
        model = settings.kb_embedding_model
        if model:
            _client.set_model(model)
    return _client


async def ingest_text(name: str, text: str) -> int:
    """Chunk and index a document. Returns the number of chunks stored (0 on failure)."""
    chunks = _chunk(text)
    if not chunks:
        return 0
    try:
        client = _get_client()
        await client.add(
            COLLECTION, documents=chunks, metadata=[{"doc": name} for _ in chunks]
        )
    except Exception:
        return 0
    return len(chunks)


async def kb_search(query: str, limit: int = 4) -> str:
    """Return the most relevant knowledge-base passages for a query, or '' if none/unavailable."""
    try:
        client = _get_client()
        hits = await client.query(COLLECTION, query_text=query, limit=limit)
    except Exception:
        return ""
    passages = [h.document for h in hits if getattr(h, "document", None)]
    return "\n\n---\n\n".join(passages)
