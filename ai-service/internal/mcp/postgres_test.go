package mcp

import (
	"context"
	"errors"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Integration test: TEST_DATABASE_URL must point at an empty scratch database
// with pgvector. It drops and recreates the ai-service tables.
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
	if _, err := pool.Exec(ctx, "DROP TABLE IF EXISTS kb_chunks, kb_documents, business_profiles, kb_audit, mcp_tokens, oauth_codes, oauth_grants, oauth_clients, team_members, admin_events, web_sources, chatwoot_inboxes, ai_pending_changes, kb_schema_version"); err != nil {
		t.Fatal(err)
	}
	if err := (&knowledge.Postgres{Pool: pool}).Migrate(ctx); err != nil {
		t.Fatal(err)
	}
	return &Postgres{Pool: pool}
}

func TestPostgres_TokenLifecycle(t *testing.T) {
	// Arrange
	db := openDB(t)
	ctx := context.Background()

	// Act
	plain, created, err := db.Create(ctx, 1, "Claude Code", true, 0)
	got, lookupErr := db.Lookup(ctx, plain)
	last := "A"
	if strings.HasSuffix(plain, "A") {
		last = "B" // always a different token
	}
	_, wrong := db.Lookup(ctx, plain[:len(plain)-1]+last)
	expPlain, expTok, _ := db.Create(ctx, 1, "short", false, time.Hour)
	// Expire it in the database's own clock (a container clock can drift from ours).
	if _, err := db.Pool.Exec(ctx, "UPDATE mcp_tokens SET expires_at = now() - interval '1 second' WHERE id = $1", expTok.ID); err != nil {
		t.Fatal(err)
	}
	_, expired := db.Lookup(ctx, expPlain)
	otherAcct := db.Revoke(ctx, 2, created.ID)
	revokeErr := db.Revoke(ctx, 1, created.ID)
	_, afterRevoke := db.Lookup(ctx, plain)
	list, _ := db.List(ctx, 1)

	// Assert
	if err != nil || !strings.HasPrefix(plain, TokenPrefix) || len(plain) < 50 {
		t.Fatalf("create: %q err=%v", plain, err)
	}
	if lookupErr != nil || got.ID != created.ID || got.AccountID != 1 || !got.CanWrite || got.LastUsedAt.IsZero() {
		t.Fatalf("lookup = %+v err=%v", got, lookupErr)
	}
	if !errors.Is(expired, ErrInvalidToken) {
		t.Fatalf("expired token accepted: %v", expired)
	}
	if !errors.Is(wrong, ErrInvalidToken) || !errors.Is(otherAcct, ErrInvalidToken) || revokeErr != nil || !errors.Is(afterRevoke, ErrInvalidToken) {
		t.Fatalf("wrong=%v otherAcct=%v revoke=%v after=%v", wrong, otherAcct, revokeErr, afterRevoke)
	}
	if len(list) != 2 || list[1].RevokedAt.IsZero() || list[0].ExpiresAt.IsZero() {
		t.Fatalf("list = %+v", list)
	}
	var stored string
	if err := db.Pool.QueryRow(ctx, "SELECT token_hash FROM mcp_tokens").Scan(&stored); err != nil || stored == plain || strings.Contains(stored, TokenPrefix) {
		t.Fatalf("the token itself must not be stored (err %v)", err)
	}
}

func TestPostgres_AuditRecordsCopy(t *testing.T) {
	// Arrange
	db := openDB(t)
	ctx := context.Background()

	// Act
	err1 := db.Record(ctx, AuditEntry{AccountID: 1, DocumentID: 5, SourceKey: "promo", Action: "delete", Actor: "mcp:claude", TokenID: 7,
		Before: map[string]any{"title": "โปรลอยกระทง", "content": "2,900"}})
	err2 := db.Record(ctx, AuditEntry{AccountID: 1, DocumentID: 6, Action: "create", Actor: "mcp:claude"})

	// Assert
	if err1 != nil || err2 != nil {
		t.Fatalf("record: %v / %v", err1, err2)
	}
	var title string
	var nulls int
	if err := db.Pool.QueryRow(ctx, `SELECT (SELECT before->>'title' FROM kb_audit WHERE action = 'delete'),
		(SELECT count(*) FROM kb_audit WHERE action = 'create' AND before IS NULL AND source_key IS NULL)`).Scan(&title, &nulls); err != nil {
		t.Fatal(err)
	}
	if title != "โปรลอยกระทง" || nulls != 1 {
		t.Fatalf("title=%q create-with-null-before=%d", title, nulls)
	}
}

func TestPostgres_NewTablesPrivateOnSupabase(t *testing.T) {
	// Arrange
	db := openDB(t)
	ctx := context.Background()

	// Act
	var rls, exposed bool
	err := db.Pool.QueryRow(ctx, `SELECT bool_and(relrowsecurity) FROM pg_class WHERE relname IN ('kb_audit', 'mcp_tokens')`).Scan(&rls)
	err2 := db.Pool.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM pg_roles r WHERE r.rolname IN ('anon', 'authenticated')
		AND (has_table_privilege(r.rolname, 'mcp_tokens', 'SELECT') OR has_table_privilege(r.rolname, 'kb_audit', 'SELECT')))`).Scan(&exposed)

	// Assert
	if err != nil || err2 != nil || !rls || exposed {
		t.Fatalf("rls=%v exposed=%v err=%v/%v", rls, exposed, err, err2)
	}
}
