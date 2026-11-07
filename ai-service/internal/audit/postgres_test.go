package audit

import (
	"context"
	"os"
	"testing"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
	"github.com/jackc/pgx/v5/pgxpool"
)

func TestPostgres_RecordAndRecentMergesAITools(t *testing.T) {
	dsn := os.Getenv("TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("TEST_DATABASE_URL not set")
	}
	// Arrange
	ctx := context.Background()
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	if _, err := pool.Exec(ctx, "DROP TABLE IF EXISTS kb_chunks, kb_documents, business_profiles, kb_audit, mcp_tokens, oauth_codes, oauth_grants, oauth_clients, team_members, admin_events, kb_schema_version"); err != nil {
		t.Fatal(err)
	}
	if err := (&knowledge.Postgres{Pool: pool}).Migrate(ctx); err != nil {
		t.Fatal(err)
	}
	db := &Postgres{Pool: pool}
	if _, err := pool.Exec(ctx, `INSERT INTO kb_audit (account_id, document_id, source_key, action, actor, before, at)
		VALUES (1, 5, 'product-017', 'update', 'mcp:Claude', '{"title":"ราคา"}', now() - interval '1 minute')`); err != nil {
		t.Fatal(err)
	}

	// Act
	e1 := db.Record(ctx, Event{AccountID: 1, Actor: "john@example.com", Action: "token created", Summary: "Codex"})
	e2 := db.Record(ctx, Event{Actor: "admin password", Action: "providers saved", Summary: "chat api.openai.com"})
	e3 := db.Record(ctx, Event{AccountID: 2, Actor: "x", Action: "token created", Summary: "other account"})
	e4 := db.Record(ctx, Event{AccountID: 1, Actor: "john@example.com", Action: "knowledge deleted", Summary: "promo", Before: map[string]any{"content": "2,900"}})
	recent, err := db.Recent(ctx, 1, 10)

	// Assert
	if e1 != nil || e2 != nil || e3 != nil || e4 != nil || err != nil {
		t.Fatalf("record %v %v %v %v recent %v", e1, e2, e3, e4, err)
	}
	if len(recent) != 4 || recent[3].Action != "knowledge edited" || recent[3].Actor != "Claude (AI tool)" || recent[3].Summary != "ราคา" {
		t.Fatalf("recent = %+v, want 3 admin events (incl. service-wide) then the AI tool change", recent)
	}
	for _, r := range recent {
		if r.Summary == "other account" {
			t.Fatal("another account's change leaked into the list")
		}
	}
	two, err := db.Recent(ctx, 1, 2)
	if err != nil || len(two) != 2 {
		t.Fatalf("limit 2 across the union: %d rows, %v", len(two), err)
	}
	// Retention: an entry older than the limit disappears on the next write.
	if _, err := pool.Exec(ctx, `INSERT INTO admin_events (account_id, actor, action, summary, at) VALUES (1, 'x', 'old', 'old', now() - interval '400 days')`); err != nil {
		t.Fatal(err)
	}
	pruning := &Postgres{Pool: pool, RetentionDays: 180}
	if err := pruning.Record(ctx, Event{AccountID: 1, Actor: "x", Action: "new", Summary: "new"}); err != nil {
		t.Fatal(err)
	}
	var old int
	if err := pool.QueryRow(ctx, `SELECT count(*) FROM admin_events WHERE action = 'old'`).Scan(&old); err != nil || old != 0 {
		t.Fatalf("old entry kept: %d %v", old, err)
	}
	var kept string
	if err := pool.QueryRow(ctx, `SELECT before->>'content' FROM admin_events WHERE action = 'knowledge deleted'`).Scan(&kept); err != nil || kept != "2,900" {
		t.Fatalf("old text not kept: %q %v", kept, err)
	}
}
