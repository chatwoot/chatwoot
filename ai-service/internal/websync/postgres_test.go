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
	dueBefore, _ := db.Claim(ctx, 10)
	claimedAgain, _ := db.Claim(ctx, 10) // leased: another run must not take them
	a.Status, a.Title, a.ContentHash, a.CheckedAt, a.ChangedAt = "ok", "Pricing", "h1", time.Now(), time.Now()
	saveErr := db.Save(ctx, a)
	if _, err := db.Pool.Exec(ctx, "UPDATE web_sources SET next_check_at = now() - interval '1 second' WHERE account_id = 2"); err != nil {
		t.Fatal(err)
	}
	dueAfter, _ := db.Claim(ctx, 10)
	got, _ := db.Get(ctx, 1, a.ID)
	_, crossGet := db.Get(ctx, 2, a.ID)
	crossRemove := db.Remove(ctx, 2, a.ID)
	removeErr := db.Remove(ctx, 1, a.ID)
	list, _ := db.List(ctx, 1)

	// Assert
	if addErr != nil || !errors.Is(dup, ErrDuplicate) || otherAcct != nil || badURL == nil {
		t.Fatalf("add=%v dup=%v other=%v bad=%v", addErr, dup, otherAcct, badURL)
	}
	if len(dueBefore) != 2 || len(claimedAgain) != 0 || len(dueAfter) != 1 || dueAfter[0].AccountID != 2 {
		t.Fatalf("claims before=%d again=%d after=%d (a checked page is not due again for 24 h)", len(dueBefore), len(claimedAgain), len(dueAfter))
	}
	if saveErr != nil || got.Title != "Pricing" || got.Status != "ok" || got.ContentHash != "h1" {
		t.Fatalf("saved = %+v err=%v", got, saveErr)
	}
	if !errors.Is(crossGet, ErrNotFound) || !errors.Is(crossRemove, ErrNotFound) || removeErr != nil || len(list) != 0 {
		t.Fatalf("crossGet=%v crossRemove=%v remove=%v list=%d", crossGet, crossRemove, removeErr, len(list))
	}
}

func TestPostgres_LimitsAndSaveAfterRemove(t *testing.T) {
	// Arrange
	db := openDB(t)
	ctx := context.Background()
	if _, err := db.Pool.Exec(ctx, `INSERT INTO web_sources (account_id, url) SELECT 1, 'https://example.com/p' || g FROM generate_series(1, $1) g`, MaxPages); err != nil {
		t.Fatal(err)
	}
	_, spaced := db.Pool.Exec(ctx, `INSERT INTO web_sources (account_id, url) VALUES (3, 'https://example.com/a b')`)
	s, _ := db.Add(ctx, 2, "https://example.com/x")

	// Act
	_, tooMany := db.Add(ctx, 1, "https://example.com/one-more")
	_ = db.Remove(ctx, 2, s.ID)
	saveGone := db.Save(ctx, s)

	// Assert
	if !errors.Is(tooMany, ErrTooMany) || spaced == nil || !errors.Is(saveGone, ErrNotFound) {
		t.Fatalf("tooMany=%v spaced=%v saveGone=%v", tooMany, spaced, saveGone)
	}
}

func TestPostgres_IntervalAndMarkAllDue(t *testing.T) {
	// Arrange
	db := openDB(t)
	ctx := context.Background()
	a, _ := db.Add(ctx, 1, "https://example.com/a")
	_, _ = db.Add(ctx, 1, "https://example.com/b")
	_, _ = db.Claim(ctx, 10)
	a.Status, a.CheckedAt = "ok", time.Now()
	_ = db.Save(ctx, a)

	// Act
	ivErr := db.SetInterval(ctx, 1, a.ID, 168)
	crossErr := db.SetInterval(ctx, 2, a.ID, 1)
	_, badIv := db.Pool.Exec(ctx, "UPDATE web_sources SET interval_hours = 1000 WHERE id = $1", a.ID)
	n, markErr := db.MarkAllDue(ctx, 1)
	due, _ := db.Claim(ctx, 10)

	// Assert
	if ivErr != nil || !errors.Is(crossErr, ErrNotFound) || badIv == nil || markErr != nil || n != 2 || len(due) != 2 {
		t.Fatalf("iv=%v cross=%v badIv=%v mark=%v n=%d due=%d", ivErr, crossErr, badIv, markErr, n, len(due))
	}
}
