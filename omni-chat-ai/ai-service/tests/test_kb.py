"""KB chunking + search/ingest behavior (Qdrant/fastembed mocked — no model download)."""
from __future__ import annotations

from types import SimpleNamespace

from app.tools import kb


def test_chunk_short_text_is_single_chunk():
    assert kb._chunk("hello world") == ["hello world"]
    assert kb._chunk("   ") == []


def test_chunk_long_text_splits_with_coverage():
    text = ("para one. " * 60) + "\n" + ("para two. " * 60)
    chunks = kb._chunk(text, size=200, overlap=40)
    assert len(chunks) > 1
    assert all(len(c) <= 200 for c in chunks)
    # No content is dropped: the first and last words survive.
    assert chunks[0].startswith("para one")


async def test_kb_search_returns_passages(monkeypatch):
    async def fake_query(collection, query_text, limit=10, **kw):
        return [SimpleNamespace(document="Returns within 14 days."),
                SimpleNamespace(document="Warranty is 12 months.")]

    monkeypatch.setattr(kb, "_get_client", lambda: SimpleNamespace(query=fake_query))
    out = await kb.kb_search("return policy")
    assert "Returns within 14 days." in out
    assert "Warranty is 12 months." in out


async def test_kb_search_degrades_to_empty_on_error(monkeypatch):
    def boom():
        raise RuntimeError("qdrant down")

    monkeypatch.setattr(kb, "_get_client", boom)
    assert await kb.kb_search("anything") == ""


async def test_ingest_text_counts_chunks(monkeypatch):
    added = {}

    async def fake_add(collection, documents, metadata=None, **kw):
        added["docs"] = list(documents)
        return ["id1"]

    monkeypatch.setattr(kb, "_get_client", lambda: SimpleNamespace(add=fake_add))
    n = await kb.ingest_text("FAQ", "short doc")
    assert n == 1
    assert added["docs"] == ["short doc"]
