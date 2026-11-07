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
	g, access, issueErr := db.CreateGrant(ctx, g, "code1", "r1", time.Hour)

	// Act
	tok, lookupErr := tokens.Lookup(ctx, access)
	rotated, _, rotErr := db.Refresh(ctx, "r1", "r2", c.ID, time.Now().Add(time.Hour), time.Hour)
	_, _, wrongClient := db.Refresh(ctx, "r2", "r3", "aisvc_client_other", time.Now().Add(time.Hour), time.Hour)
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
	g, access, err := db.CreateGrant(ctx, Grant{AccountID: 1, ClientID: c.ID, ClientName: c.Name, RefreshExpiresAt: time.Now().Add(time.Hour)}, "c1", "r1", time.Hour)
	if err != nil {
		t.Fatal(err)
	}
	id := g.ID

	// Act
	_, _, first := db.Refresh(ctx, "r1", "r2", c.ID, time.Now().Add(time.Hour), time.Hour)
	_, _, retry := db.Refresh(ctx, "r1", "r3", c.ID, time.Now().Add(time.Hour), time.Hour) // within the grace period
	if _, err := db.Pool.Exec(ctx, "UPDATE oauth_grants SET rotated_at = now() - interval '1 minute' WHERE id = $1", id); err != nil {
		t.Fatal(err)
	}
	_, _, reuse := db.Refresh(ctx, "r1", "r3", c.ID, time.Now().Add(time.Hour), time.Hour)
	_, _, current := db.Refresh(ctx, "r2", "r4", c.ID, time.Now().Add(time.Hour), time.Hour)
	// v5 binary's Lookup SQL: only mcp_tokens' own revoked_at
	var oldBinarySees int
	_ = db.Pool.QueryRow(ctx, `SELECT count(*) FROM mcp_tokens WHERE token_hash = $1 AND revoked_at IS NULL
		AND (expires_at IS NULL OR expires_at > now())`, mcp.HashToken(access)).Scan(&oldBinarySees)
	grants, _ := db.Grants(ctx, 1)

	// Assert
	if first != nil || !errors.Is(retry, ErrNotFound) || !errors.Is(reuse, ErrRefreshReuse) || !errors.Is(current, ErrNotFound) {
		t.Fatalf("first=%v retry=%v reuse=%v current=%v", first, retry, reuse, current)
	}
	if oldBinarySees != 0 {
		t.Error("an older binary would still accept the revoked app's access token")
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
	g, _, grantErr := db.CreateGrant(ctx, Grant{AccountID: 1, ClientID: "c", ClientName: "x", RefreshExpiresAt: time.Now().Add(time.Hour)}, "h1", "r", time.Hour)
	_, again := db.TakeCode(ctx, "h1")
	_, expired := db.TakeCode(ctx, "h2")
	grants, _ := db.Grants(ctx, 1)

	// Assert
	if firstErr != nil || grantErr != nil || got.AccountID != 1 || !errors.Is(again, ErrCodeReuse) || !errors.Is(expired, ErrNotFound) {
		t.Fatalf("first=%v grant=%v again=%v expired=%v", firstErr, grantErr, again, expired)
	}
	if len(grants) != 1 || grants[0].ID != g.ID || grants[0].RevokedAt.IsZero() {
		t.Fatalf("code reuse did not revoke the connection: %+v", grants)
	}
}

func TestPostgres_RevokeGrantOnlyOwnAccount(t *testing.T) {
	// Arrange
	db := openDB(t)
	ctx := context.Background()
	g, _, err := db.CreateGrant(ctx, Grant{AccountID: 2, ClientID: "c", ClientName: "x", RefreshExpiresAt: time.Now().Add(time.Hour)}, "c2", "r", time.Hour)
	if err != nil {
		t.Fatal(err)
	}

	// Act
	cross := db.RevokeGrant(ctx, 1, g.ID)

	// Assert
	if !errors.Is(cross, ErrNotFound) {
		t.Fatalf("cross-account revoke = %v", cross)
	}
}

func TestPostgres_OlderRefreshTokenAlsoRevokes(t *testing.T) {
	// Arrange: r1 -> r2 -> r3; r1 is two generations old.
	db := openDB(t)
	ctx := context.Background()
	c, _ := db.RegisterClient(ctx, "Claude", []string{"https://claude.ai/cb"})
	if _, _, err := db.CreateGrant(ctx, Grant{AccountID: 1, ClientID: c.ID, ClientName: c.Name, RefreshExpiresAt: time.Now().Add(time.Hour)}, "c", "r1", time.Hour); err != nil {
		t.Fatal(err)
	}
	for _, step := range [][2]string{{"r1", "r2"}, {"r2", "r3"}} {
		if _, _, err := db.Refresh(ctx, step[0], step[1], c.ID, time.Now().Add(time.Hour), time.Hour); err != nil {
			t.Fatal(err)
		}
	}

	// Act
	_, _, err := db.Refresh(ctx, "r1", "rx", c.ID, time.Now().Add(time.Hour), time.Hour)
	_, _, current := db.Refresh(ctx, "r3", "r4", c.ID, time.Now().Add(time.Hour), time.Hour)

	// Assert
	if !errors.Is(err, ErrRefreshReuse) || !errors.Is(current, ErrNotFound) {
		t.Fatalf("old token: %v, current after revoke: %v", err, current)
	}
}
