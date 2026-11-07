package knowledge

import (
	"context"
	_ "embed"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

//go:embed schema.sql
var schemaV1 string

//go:embed schema_v2.sql
var schemaV2 string

//go:embed schema_v3.sql
var schemaV3 string

//go:embed schema_v4.sql
var schemaV4 string

//go:embed schema_v5.sql
var schemaV5 string

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
	if version < 2 {
		if _, err := tx.Exec(ctx, schemaV2); err != nil {
			return fmt.Errorf("apply schema v2: %w", err)
		}
		if _, err := tx.Exec(ctx, "UPDATE kb_schema_version SET version = 2"); err != nil {
			return err
		}
	}
	if version < 3 {
		if _, err := tx.Exec(ctx, schemaV3); err != nil {
			return fmt.Errorf("apply schema v3: %w", err)
		}
		if _, err := tx.Exec(ctx, "UPDATE kb_schema_version SET version = 3"); err != nil {
			return err
		}
	}
	if version < 4 {
		if _, err := tx.Exec(ctx, schemaV4); err != nil {
			return fmt.Errorf("apply schema v4: %w", err)
		}
		if _, err := tx.Exec(ctx, "UPDATE kb_schema_version SET version = 4"); err != nil {
			return err
		}
	}
	if version < 5 {
		if _, err := tx.Exec(ctx, schemaV5); err != nil {
			return fmt.Errorf("apply schema v5: %w", err)
		}
		if _, err := tx.Exec(ctx, "UPDATE kb_schema_version SET version = 5"); err != nil {
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

func nullableTime(t time.Time) any {
	if t.IsZero() {
		return nil
	}
	return t
}

func nullableKey(k string) any {
	if k == "" {
		return nil
	}
	return k
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
	err = tx.QueryRow(ctx, `INSERT INTO kb_documents (account_id, inbox_id, kind, title, content, valid_from, valid_until, source_key)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING id`,
		d.AccountID, nullableInbox(d.InboxID), string(d.Kind), d.Title, d.Content,
		nullableTime(d.ValidFrom), nullableTime(d.ValidUntil), nullableKey(d.SourceKey)).Scan(&d.ID)
	if err != nil {
		return 0, err
	}
	if err := insertChunks(ctx, tx, d, model, chunks); err != nil {
		return 0, err
	}
	return d.ID, tx.Commit(ctx)
}

// ReplaceChunks implements Store. d is the document as read (ID, AccountID,
// UpdatedAt): if it was edited or deleted since, nothing is written, so a
// slow re-index can never put back chunks of text an admin just replaced.
func (p *Postgres) ReplaceChunks(ctx context.Context, d Document, model string, chunks []Chunk) error {
	tx, err := p.Pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	err = tx.QueryRow(ctx, `UPDATE kb_documents SET updated_at = now()
		WHERE id = $1 AND account_id = $2 AND updated_at = $3
		RETURNING id, account_id, COALESCE(inbox_id, 0)`, d.ID, d.AccountID, d.UpdatedAt).Scan(&d.ID, &d.AccountID, &d.InboxID)
	if errors.Is(err, pgx.ErrNoRows) {
		var exists bool
		if err := tx.QueryRow(ctx, "SELECT EXISTS (SELECT 1 FROM kb_documents WHERE id = $1 AND account_id = $2)",
			d.ID, d.AccountID).Scan(&exists); err != nil {
			return err
		}
		if exists {
			return ErrChanged
		}
		return ErrNotFound
	}
	if err != nil {
		return err
	}
	if _, err := tx.Exec(ctx, "DELETE FROM kb_chunks WHERE document_id = $1", d.ID); err != nil {
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
		SELECT `+docColumns+`,
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
		var chunks, stale int
		d, err := scanDocument(r.Scan, &chunks, &stale)
		d.Chunks, d.StaleChunks = chunks, stale
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
		  AND ($6 OR ((d.valid_from IS NULL OR d.valid_from <= now())
		          AND (d.valid_until IS NULL OR d.valid_until > now())))
		ORDER BY c.embedding <=> $1::vector
		LIMIT $5`,
		vectorLiteral(q.Vector), q.AccountID, q.InboxID, q.Model, max(q.Limit, 1), q.IncludeInactive)
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

// docColumns are the kb_documents columns scanDocument reads, in order.
const docColumns = `d.id, d.account_id, COALESCE(d.inbox_id, 0), d.kind, d.title, d.content, d.updated_at,
		       d.valid_from, d.valid_until, d.use_count, d.last_used_at, COALESCE(d.source_key, '')`

// scanDocument reads docColumns (plus any extra trailing columns) from one row.
func scanDocument(scan func(dest ...any) error, extra ...any) (Document, error) {
	var d Document
	var kind string
	var from, until, used *time.Time
	dest := append([]any{&d.ID, &d.AccountID, &d.InboxID, &kind, &d.Title, &d.Content, &d.UpdatedAt,
		&from, &until, &d.UseCount, &used, &d.SourceKey}, extra...)
	if err := scan(dest...); err != nil {
		return Document{}, err
	}
	d.Kind = Kind(kind)
	if from != nil {
		d.ValidFrom = *from
	}
	if until != nil {
		d.ValidUntil = *until
	}
	if used != nil {
		d.LastUsedAt = *used
	}
	return d, nil
}

// Get implements Store.
func (p *Postgres) Get(ctx context.Context, accountID, id int64) (Document, error) {
	row := p.Pool.QueryRow(ctx, `SELECT `+docColumns+` FROM kb_documents d WHERE d.id = $1 AND d.account_id = $2`, id, accountID)
	d, err := scanDocument(row.Scan)
	if errors.Is(err, pgx.ErrNoRows) {
		return Document{}, ErrNotFound
	}
	return d, err
}

// GetByKey implements Store.
func (p *Postgres) GetByKey(ctx context.Context, accountID int64, key string) (Document, error) {
	if key == "" {
		return Document{}, ErrNotFound
	}
	row := p.Pool.QueryRow(ctx, `SELECT `+docColumns+` FROM kb_documents d WHERE d.account_id = $1 AND d.source_key = $2`, accountID, key)
	d, err := scanDocument(row.Scan)
	if errors.Is(err, pgx.ErrNoRows) {
		return Document{}, ErrNotFound
	}
	return d, err
}

// Update implements Store: new text, scope and dates, and fresh chunks, in
// one transaction. Usage counters are kept.
func (p *Postgres) Update(ctx context.Context, d Document, model string, chunks []Chunk) error {
	tx, err := p.Pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	tag, err := tx.Exec(ctx, `UPDATE kb_documents
		SET title = $3, content = $4, inbox_id = $5, valid_from = $6, valid_until = $7, updated_at = now()
		WHERE id = $1 AND account_id = $2`,
		d.ID, d.AccountID, d.Title, d.Content, nullableInbox(d.InboxID), nullableTime(d.ValidFrom), nullableTime(d.ValidUntil))
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	if _, err := tx.Exec(ctx, "DELETE FROM kb_chunks WHERE document_id = $1", d.ID); err != nil {
		return err
	}
	if err := insertChunks(ctx, tx, d, model, chunks); err != nil {
		return err
	}
	return tx.Commit(ctx)
}

// MarkUsed implements Store.
func (p *Postgres) MarkUsed(ctx context.Context, accountID int64, ids []int64) error {
	if len(ids) == 0 {
		return nil
	}
	_, err := p.Pool.Exec(ctx, `UPDATE kb_documents SET use_count = use_count + 1, last_used_at = now()
		WHERE account_id = $1 AND id = ANY($2)`, accountID, ids)
	return err
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
