package knowledge

import (
	"context"
	"errors"
	"os"
	"testing"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/embed"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Integration test: set TEST_DATABASE_URL to an empty scratch database with
// pgvector available, e.g. postgres://postgres:...@localhost:5432/ai_service_test.
// The test drops and recreates the kb_* tables.
func openTestDB(t *testing.T) *Postgres {
	t.Helper()
	dsn := os.Getenv("TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("TEST_DATABASE_URL not set")
	}
	ctx := context.Background()
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	if _, err := pool.Exec(ctx, "DROP TABLE IF EXISTS kb_chunks, kb_documents, kb_schema_version"); err != nil {
		t.Fatal(err)
	}
	p := &Postgres{Pool: pool}
	if err := p.Migrate(ctx); err != nil {
		t.Fatal(err)
	}
	if err := p.Migrate(ctx); err != nil { // second run must be a no-op
		t.Fatalf("re-migrate: %v", err)
	}
	return p
}

// axis returns a unit vector along dimension i, so similarity is exact.
func axis(i int) []float32 {
	v := make([]float32, embed.Dimensions)
	v[i] = 1
	return v
}

func TestPostgres_InsertSearchScopesAndDelete(t *testing.T) {
	// Arrange
	p := openTestDB(t)
	ctx := context.Background()
	add := func(acct, inbox int64, title string, dim int, model string) int64 {
		id, err := p.Insert(ctx, Document{AccountID: acct, InboxID: inbox, Kind: KindText, Title: title, Content: "c"},
			model, []Chunk{{Ord: 0, Content: title, Embedding: axis(dim)}})
		if err != nil {
			t.Fatal(err)
		}
		return id
	}
	shared := add(1, 0, "all inboxes", 0, "m1")
	add(1, 5, "inbox 5", 0, "m1")
	add(1, 6, "inbox 6", 0, "m1")
	add(2, 0, "other account", 0, "m1")
	add(1, 0, "old model", 0, "m0")
	add(1, 0, "unrelated", 1, "m1")

	// Act
	hits, err := p.Search(ctx, Query{AccountID: 1, InboxID: 5, Model: "m1", Vector: axis(0), Limit: 10})

	// Assert
	if err != nil {
		t.Fatal(err)
	}
	got := map[string]float64{}
	for _, h := range hits {
		got[h.Title] = h.Score
	}
	if len(got) != 3 || got["all inboxes"] < 0.99 || got["inbox 5"] < 0.99 || got["unrelated"] > 0.01 {
		t.Errorf("hits = %v", got)
	}
	if hits[len(hits)-1].Title != "unrelated" {
		t.Errorf("not ordered by similarity: %+v", hits)
	}

	// Act: list shows stale chunks for the old model; delete is account-scoped.
	docs, errList := p.List(ctx, 1, "m1")
	errOther := p.Delete(ctx, 2, shared)
	errOwn := p.Delete(ctx, 1, shared)

	// Assert
	if errList != nil || len(docs) != 5 {
		t.Fatalf("list: %d docs, err=%v", len(docs), errList)
	}
	stale := 0
	for _, d := range docs {
		stale += d.StaleChunks
	}
	if stale != 1 {
		t.Errorf("stale chunks = %d, want 1", stale)
	}
	if !errors.Is(errOther, ErrNotFound) || errOwn != nil {
		t.Errorf("delete other=%v own=%v", errOther, errOwn)
	}
}

func TestPostgres_ReplaceChunks(t *testing.T) {
	// Arrange
	p := openTestDB(t)
	ctx := context.Background()
	id, err := p.Insert(ctx, Document{AccountID: 1, Kind: KindText, Title: "t", Content: "c"},
		"m0", []Chunk{{Content: "a", Embedding: axis(0)}, {Ord: 1, Content: "b", Embedding: axis(1)}})
	if err != nil {
		t.Fatal(err)
	}

	// Act
	err = p.ReplaceChunks(ctx, id, "m1", []Chunk{{Content: "new", Embedding: axis(2)}})
	missing := p.ReplaceChunks(ctx, id+999, "m1", nil)

	// Assert
	if err != nil || !errors.Is(missing, ErrNotFound) {
		t.Fatalf("err=%v missing=%v", err, missing)
	}
	docs, _ := p.List(ctx, 1, "m1")
	if len(docs) != 1 || docs[0].Chunks != 1 || docs[0].StaleChunks != 0 {
		t.Errorf("docs = %+v", docs)
	}
}
