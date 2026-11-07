package oauth

import (
	"context"
	"errors"
	"os"
	"testing"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/mcp"
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
	if _, err := pool.Exec(ctx, "DROP TABLE IF EXISTS kb_chunks, kb_documents, business_profiles, kb_audit, mcp_tokens, oauth_codes, oauth_grants, oauth_clients, kb_schema_version"); err != nil {
		t.Fatal(err)
	}
	if err := (&knowledge.Postgres{Pool: pool}).Migrate(ctx); err != nil {
		t.Fatal(err)
	}
	return &Postgres{Pool: pool}
}

func TestPostgres_GrantLifecycleCutsAccessTokens(t *testing.T) {
	// Arrange
	db := openDB(t)
	ctx := context.Background()
	tokens := &mcp.Postgres{Pool: db.Pool}
	c, err := db.RegisterClient(ctx, "Claude", []string{"https://claude.ai/api/mcp/auth_callback"})
	if err != nil {
		t.Fatal(err)
	}
	g := Grant{AccountID: 1, ClientID: c.ID, ClientName: c.Name, CanWrite: true, RefreshExpiresAt: time.Now().Add(time.Hour)}
	g.ID, err = db.CreateGrant(ctx, g, "r1")
	if err != nil {
		t.Fatal(err)
	}

	// Act
	access, issueErr := db.IssueAccess(ctx, g, time.Hour)
	tok, lookupErr := tokens.Lookup(ctx, access)
	rotated, rotErr := db.RotateRefresh(ctx, "r1", "r2", c.ID, time.Now().Add(time.Hour))
	_, wrongClient := db.RotateRefresh(ctx, "r2", "r3", "aisvc_client_other", time.Now().Add(time.Hour))
	manual, _ := tokens.List(ctx, 1)
	revokeErr := db.RevokeGrant(ctx, 1, g.ID)
	_, afterRevoke := tokens.Lookup(ctx, access)
	grants, _ := db.Grants(ctx, 1)

	// Assert
	if issueErr != nil || lookupErr != nil || tok.AccountID != 1 || !tok.CanWrite || tok.Name != "Claude" {
		t.Fatalf("issue %v lookup %v tok %+v", issueErr, lookupErr, tok)
	}
	if rotErr != nil || rotated.ID != g.ID || !errors.Is(wrongClient, ErrNotFound) {
		t.Fatalf("rotate %v wrongClient %v", rotErr, wrongClient)
	}
	if len(manual) != 0 {
		t.Errorf("app access tokens listed as manual tokens: %d", len(manual))
	}
	if revokeErr != nil || !errors.Is(afterRevoke, mcp.ErrInvalidToken) || len(grants) != 1 || grants[0].RevokedAt.IsZero() {
		t.Fatalf("revoke %v afterRevoke %v grants %+v", revokeErr, afterRevoke, grants)
	}
}

func TestPostgres_RefreshReuseRevokesGrant(t *testing.T) {
	// Arrange
	db := openDB(t)
	ctx := context.Background()
	c, _ := db.RegisterClient(ctx, "ChatGPT", []string{"https://chatgpt.com/cb"})
	id, err := db.CreateGrant(ctx, Grant{AccountID: 1, ClientID: c.ID, ClientName: c.Name, RefreshExpiresAt: time.Now().Add(time.Hour)}, "r1")
	if err != nil {
		t.Fatal(err)
	}

	// Act
	_, first := db.RotateRefresh(ctx, "r1", "r2", c.ID, time.Now().Add(time.Hour))
	_, reuse := db.RotateRefresh(ctx, "r1", "r3", c.ID, time.Now().Add(time.Hour))
	_, current := db.RotateRefresh(ctx, "r2", "r4", c.ID, time.Now().Add(time.Hour))
	grants, _ := db.Grants(ctx, 1)

	// Assert
	if first != nil || !errors.Is(reuse, ErrRefreshReuse) || !errors.Is(current, ErrNotFound) {
		t.Fatalf("first=%v reuse=%v current=%v", first, reuse, current)
	}
	if len(grants) != 1 || grants[0].ID != id || grants[0].RevokedAt.IsZero() {
		t.Fatalf("grant not revoked: %+v", grants)
	}
}

func TestPostgres_CodesWorkOnceAndExpire(t *testing.T) {
	// Arrange
	db := openDB(t)
	ctx := context.Background()
	base := Code{ClientID: "c", RedirectURI: "https://x/cb", Challenge: "ch", Resource: "https://x/mcp", AccountID: 1}
	live, old := base, base
	live.Hash, live.ExpiresAt = "h1", time.Now().Add(time.Minute)
	old.Hash, old.ExpiresAt = "h2", time.Now().Add(-time.Second)
	if err := db.SaveCode(ctx, live); err != nil {
		t.Fatal(err)
	}
	if err := db.SaveCode(ctx, old); err != nil {
		t.Fatal(err)
	}

	// Act
	got, firstErr := db.TakeCode(ctx, "h1")
	_, again := db.TakeCode(ctx, "h1")
	_, expired := db.TakeCode(ctx, "h2")

	// Assert
	if firstErr != nil || got.AccountID != 1 || !errors.Is(again, ErrNotFound) || !errors.Is(expired, ErrNotFound) {
		t.Fatalf("first=%v again=%v expired=%v", firstErr, again, expired)
	}
}

func TestPostgres_RevokeGrantOnlyOwnAccount(t *testing.T) {
	// Arrange
	db := openDB(t)
	ctx := context.Background()
	id, err := db.CreateGrant(ctx, Grant{AccountID: 2, ClientID: "c", ClientName: "x", RefreshExpiresAt: time.Now().Add(time.Hour)}, "r")
	if err != nil {
		t.Fatal(err)
	}

	// Act
	cross := db.RevokeGrant(ctx, 1, id)

	// Assert
	if !errors.Is(cross, ErrNotFound) {
		t.Fatalf("cross-account revoke = %v", cross)
	}
}
