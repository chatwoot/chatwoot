-- Knowledge base schema, version 1. Applied once by Migrate.
-- The vector extension must already exist (created by a superuser) or be
-- creatable by the connecting role.
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS kb_documents (
    id         BIGSERIAL PRIMARY KEY,
    account_id BIGINT      NOT NULL,
    inbox_id   BIGINT,                -- NULL = every inbox of the account
    kind       TEXT        NOT NULL CHECK (kind IN ('faq', 'text')),
    title      TEXT        NOT NULL,
    content    TEXT        NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS kb_documents_account_idx ON kb_documents (account_id, updated_at DESC);

CREATE TABLE IF NOT EXISTS kb_chunks (
    id              BIGSERIAL PRIMARY KEY,
    document_id     BIGINT       NOT NULL REFERENCES kb_documents (id) ON DELETE CASCADE,
    account_id      BIGINT       NOT NULL,
    inbox_id        BIGINT,
    ord             INT          NOT NULL,
    content         TEXT         NOT NULL,
    embedding_model TEXT         NOT NULL,
    embedding       vector(1536) NOT NULL
);
CREATE INDEX IF NOT EXISTS kb_chunks_document_idx ON kb_chunks (document_id);
CREATE INDEX IF NOT EXISTS kb_chunks_account_idx ON kb_chunks (account_id, embedding_model);
CREATE INDEX IF NOT EXISTS kb_chunks_embedding_idx ON kb_chunks USING hnsw (embedding vector_cosine_ops);
