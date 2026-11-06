package knowledge

import (
	"context"
	_ "embed"
	"errors"
	"fmt"
	"strconv"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

//go:embed schema.sql
var schemaV1 string

// Postgres is a Store backed by Postgres with the pgvector extension.
type Postgres struct {
	Pool *pgxpool.Pool
}

// migrationLock serialises Migrate across replicas (pg_advisory_xact_lock key).
const migrationLock = 7_301_265

// Migrate creates or upgrades the schema. Safe to run on every start.
func (p *Postgres) Migrate(ctx context.Context) error {
	tx, err := p.Pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx) //nolint:errcheck // no-op after commit
	if _, err := tx.Exec(ctx, "SELECT pg_advisory_xact_lock($1)", migrationLock); err != nil {
		return err
	}
	if _, err := tx.Exec(ctx, "CREATE TABLE IF NOT EXISTS kb_schema_version (version INT NOT NULL)"); err != nil {
		return err
	}
	var version int
	err = tx.QueryRow(ctx, "SELECT version FROM kb_schema_version").Scan(&version)
	if errors.Is(err, pgx.ErrNoRows) {
		if _, err := tx.Exec(ctx, "INSERT INTO kb_schema_version VALUES (0)"); err != nil {
			return err
		}
	} else if err != nil {
		return err
	}
	if version < 1 {
		// No arguments → simple protocol, which allows several statements.
		if _, err := tx.Exec(ctx, schemaV1); err != nil {
			return fmt.Errorf("apply schema v1: %w", err)
		}
		if _, err := tx.Exec(ctx, "UPDATE kb_schema_version SET version = 1"); err != nil {
			return err
		}
	}
	return tx.Commit(ctx)
}

// vectorLiteral formats a vector the way pgvector parses it: [1,2,3].
func vectorLiteral(v []float32) string {
	var b strings.Builder
	b.Grow(len(v) * 10)
	b.WriteByte('[')
	for i, f := range v {
		if i > 0 {
			b.WriteByte(',')
		}
		b.WriteString(strconv.FormatFloat(float64(f), 'g', -1, 32))
	}
	b.WriteByte(']')
	return b.String()
}

func nullableInbox(id int64) any {
	if id == 0 {
		return nil
	}
	return id
}

func insertChunks(ctx context.Context, tx pgx.Tx, d Document, model string, chunks []Chunk) error {
	batch := &pgx.Batch{}
	for _, c := range chunks {
		batch.Queue(`INSERT INTO kb_chunks (document_id, account_id, inbox_id, ord, content, embedding_model, embedding)
			VALUES ($1, $2, $3, $4, $5, $6, $7::vector)`,
			d.ID, d.AccountID, nullableInbox(d.InboxID), c.Ord, c.Content, model, vectorLiteral(c.Embedding))
	}
	return tx.SendBatch(ctx, batch).Close()
}

// Insert implements Store.
func (p *Postgres) Insert(ctx context.Context, d Document, model string, chunks []Chunk) (int64, error) {
	tx, err := p.Pool.Begin(ctx)
	if err != nil {
		return 0, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	err = tx.QueryRow(ctx, `INSERT INTO kb_documents (account_id, inbox_id, kind, title, content)
		VALUES ($1, $2, $3, $4, $5) RETURNING id`,
		d.AccountID, nullableInbox(d.InboxID), string(d.Kind), d.Title, d.Content).Scan(&d.ID)
	if err != nil {
		return 0, err
	}
	if err := insertChunks(ctx, tx, d, model, chunks); err != nil {
		return 0, err
	}
	return d.ID, tx.Commit(ctx)
}

// ReplaceChunks implements Store.
func (p *Postgres) ReplaceChunks(ctx context.Context, documentID int64, model string, chunks []Chunk) error {
	tx, err := p.Pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	var d Document
	err = tx.QueryRow(ctx, `UPDATE kb_documents SET updated_at = now() WHERE id = $1
		RETURNING id, account_id, COALESCE(inbox_id, 0)`, documentID).Scan(&d.ID, &d.AccountID, &d.InboxID)
	if errors.Is(err, pgx.ErrNoRows) {
		return ErrNotFound
	}
	if err != nil {
		return err
	}
	if _, err := tx.Exec(ctx, "DELETE FROM kb_chunks WHERE document_id = $1", documentID); err != nil {
		return err
	}
	if err := insertChunks(ctx, tx, d, model, chunks); err != nil {
		return err
	}
	return tx.Commit(ctx)
}

// List implements Store. Newest first, at most 500 documents.
func (p *Postgres) List(ctx context.Context, accountID int64, model string) ([]Document, error) {
	rows, err := p.Pool.Query(ctx, `
		SELECT d.id, d.account_id, COALESCE(d.inbox_id, 0), d.kind, d.title, d.content, d.updated_at,
		       COUNT(c.id), COUNT(c.id) FILTER (WHERE c.embedding_model <> $2)
		FROM kb_documents d
		LEFT JOIN kb_chunks c ON c.document_id = d.id
		WHERE d.account_id = $1
		GROUP BY d.id
		ORDER BY d.updated_at DESC, d.id DESC
		LIMIT 500`, accountID, model)
	if err != nil {
		return nil, err
	}
	return pgx.CollectRows(rows, func(r pgx.CollectableRow) (Document, error) {
		var d Document
		var kind string
		err := r.Scan(&d.ID, &d.AccountID, &d.InboxID, &kind, &d.Title, &d.Content, &d.UpdatedAt, &d.Chunks, &d.StaleChunks)
		d.Kind = Kind(kind)
		return d, err
	})
}

// Delete implements Store. Chunks go with the document (ON DELETE CASCADE).
func (p *Postgres) Delete(ctx context.Context, accountID, id int64) error {
	tag, err := p.Pool.Exec(ctx, "DELETE FROM kb_documents WHERE id = $1 AND account_id = $2", id, accountID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

// Search implements Store: cosine similarity, filtered by account, inbox and
// embedding model. Iterative index scans (pgvector ≥ 0.8) keep filtered
// searches from returning too few rows.
func (p *Postgres) Search(ctx context.Context, q Query) ([]Hit, error) {
	tx, err := p.Pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	if _, err := tx.Exec(ctx, "SET LOCAL hnsw.iterative_scan = relaxed_order"); err != nil {
		return nil, err
	}
	rows, err := tx.Query(ctx, `
		SELECT c.id, c.document_id, d.title, c.content, 1 - (c.embedding <=> $1::vector) AS score
		FROM kb_chunks c
		JOIN kb_documents d ON d.id = c.document_id
		WHERE c.account_id = $2
		  AND (c.inbox_id IS NULL OR c.inbox_id = $3)
		  AND c.embedding_model = $4
		ORDER BY c.embedding <=> $1::vector
		LIMIT $5`,
		vectorLiteral(q.Vector), q.AccountID, q.InboxID, q.Model, max(q.Limit, 1))
	if err != nil {
		return nil, err
	}
	hits, err := pgx.CollectRows(rows, func(r pgx.CollectableRow) (Hit, error) {
		var h Hit
		err := r.Scan(&h.ChunkID, &h.DocumentID, &h.Title, &h.Content, &h.Score)
		return h, err
	})
	if err != nil {
		return nil, err
	}
	return hits, tx.Commit(ctx)
}

// OpenPostgres connects, checks the connection and applies migrations.
// Call Close on the returned store's Pool when done.
func OpenPostgres(ctx context.Context, dsn string) (*Postgres, error) {
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		return nil, fmt.Errorf("database config: %w", err)
	}
	if err := pool.Ping(ctx); err != nil {
		pool.Close()
		return nil, fmt.Errorf("database ping: %w", err)
	}
	p := &Postgres{Pool: pool}
	if err := p.Migrate(ctx); err != nil {
		pool.Close()
		return nil, fmt.Errorf("database migrate: %w", err)
	}
	return p, nil
}
