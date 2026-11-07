package websync

import (
	"context"
	"errors"
	"os"
	"testing"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
	"github.com/jackc/pgx/v5/pgxpool"
)

func openDB(t *testing.T) *Postgres {
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
	if _, err := pool.Exec(ctx, "DROP TABLE IF EXISTS kb_chunks, kb_documents, business_profiles, kb_audit, mcp_tokens, oauth_codes, oauth_grants, oauth_clients, team_members, admin_events, web_sources, kb_schema_version"); err != nil {
		t.Fatal(err)
	}
	if err := (&knowledge.Postgres{Pool: pool}).Migrate(ctx); err != nil {
		t.Fatal(err)
	}
	return &Postgres{Pool: pool}
}

func TestPostgres_SourcesAddDueSaveRemove(t *testing.T) {
	// Arrange
	db := openDB(t)
	ctx := context.Background()

	// Act
	a, addErr := db.Add(ctx, 1, "https://example.com/pricing")
	_, dup := db.Add(ctx, 1, "https://example.com/pricing")
	_, otherAcct := db.Add(ctx, 2, "https://example.com/pricing")
	_, badURL := db.Add(ctx, 1, "javascript:alert(1)")
	dueBefore, _ := db.Due(ctx, 10)
	a.Status, a.Title, a.ContentHash, a.CheckedAt, a.ChangedAt = "ok", "Pricing", "h1", time.Now(), time.Now()
	saveErr := db.Save(ctx, a)
	dueAfter, _ := db.Due(ctx, 10)
	got, _ := db.Get(ctx, 1, a.ID)
	_, crossGet := db.Get(ctx, 2, a.ID)
	crossRemove := db.Remove(ctx, 2, a.ID)
	removeErr := db.Remove(ctx, 1, a.ID)
	list, _ := db.List(ctx, 1)

	// Assert
	if addErr != nil || !errors.Is(dup, ErrDuplicate) || otherAcct != nil || badURL == nil {
		t.Fatalf("add=%v dup=%v other=%v bad=%v", addErr, dup, otherAcct, badURL)
	}
	if len(dueBefore) != 2 || len(dueAfter) != 1 {
		t.Fatalf("due before=%d after=%d (a checked page is not due again for 24 h)", len(dueBefore), len(dueAfter))
	}
	if saveErr != nil || got.Title != "Pricing" || got.Status != "ok" || got.ContentHash != "h1" {
		t.Fatalf("saved = %+v err=%v", got, saveErr)
	}
	if !errors.Is(crossGet, ErrNotFound) || !errors.Is(crossRemove, ErrNotFound) || removeErr != nil || len(list) != 0 {
		t.Fatalf("crossGet=%v crossRemove=%v remove=%v list=%d", crossGet, crossRemove, removeErr, len(list))
	}
}
