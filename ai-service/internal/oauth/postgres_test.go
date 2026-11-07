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
	if _, err := pool.Exec(ctx, "DROP TABLE IF EXISTS kb_chunks, kb_documents, business_profiles, kb_audit, mcp_tokens, oauth_codes, oauth_grants, oauth_clients, team_members, admin_events, web_sources, kb_schema_version"); err != nil {
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

func TestPostgres_TeamAndRemovalDisconnectsTheirApps(t *testing.T) {
	// Arrange
	db := openDB(t)
	ctx := context.Background()
	tokens := &mcp.Postgres{Pool: db.Pool}
	for _, m := range []Member{{Email: "Somchai@Example.com", AccountID: 1, CanWrite: true}, {Email: "somchai@example.com", AccountID: 2}, {Email: "nok@example.com", AccountID: 1}} {
		if err := db.AddMember(ctx, m); err != nil {
			t.Fatal(err)
		}
	}
	if err := db.AddMember(ctx, Member{Email: "nok@example.com", AccountID: 1, CanWrite: true}); err != nil { // change access
		t.Fatal(err)
	}
	grant := func(acct int64, by string) string {
		g, access, err := db.CreateGrant(ctx, Grant{AccountID: acct, ClientID: "c", ClientName: "Claude", ApprovedBy: by,
			RefreshExpiresAt: time.Now().Add(time.Hour)}, "code-"+by+string(rune('0'+acct)), "r-"+by+string(rune('0'+acct)), time.Hour)
		if err != nil || g.ApprovedBy != by {
			t.Fatalf("grant: %v %+v", err, g)
		}
		return access
	}
	somchai1, somchai2, nok1 := grant(1, "somchai@example.com"), grant(2, "somchai@example.com"), grant(1, "nok@example.com")

	// Act
	mine, _ := db.Memberships(ctx, "SOMCHAI@example.com")
	team1, _ := db.Team(ctx, 1)
	removeErr := db.RemoveMember(ctx, "somchai@example.com", 1)
	missing := db.RemoveMember(ctx, "somchai@example.com", 1)
	_, s1 := tokens.Lookup(ctx, somchai1)
	_, s2 := tokens.Lookup(ctx, somchai2)
	_, n1 := tokens.Lookup(ctx, nok1)

	// Assert
	if len(mine) != 2 || len(team1) != 2 || !team1[0].CanWrite || !team1[1].CanWrite {
		t.Fatalf("memberships=%+v team1=%+v", mine, team1)
	}
	if removeErr != nil || !errors.Is(missing, ErrNotFound) {
		t.Fatalf("remove=%v missing=%v", removeErr, missing)
	}
	if !errors.Is(s1, mcp.ErrInvalidToken) || s2 != nil || n1 != nil {
		t.Fatalf("after removing somchai from account 1: theirs(1)=%v theirs(2)=%v nok(1)=%v", s1, s2, n1)
	}
}

func TestPostgres_TeamEmailMustBeLowerCase(t *testing.T) {
	// Arrange
	db := openDB(t)

	// Act
	_, err := db.Pool.Exec(context.Background(), `INSERT INTO team_members (email, account_id) VALUES ('Boss@Example.com', 1)`)

	// Assert
	if err == nil {
		t.Fatal("mixed-case email stored directly")
	}
}

func TestPostgres_RemovedBeforeCodeExchangeGetsNothing(t *testing.T) {
	// Arrange: approved (code saved), then removed before the app exchanges it.
	db := openDB(t)
	ctx := context.Background()
	if err := db.AddMember(ctx, Member{Email: "somchai@example.com", AccountID: 1, CanWrite: true}); err != nil {
		t.Fatal(err)
	}
	code := Code{Hash: "h", ClientID: "c", RedirectURI: "https://x/cb", Challenge: "ch", Resource: "r", AccountID: 1, CanWrite: true,
		ExpiresAt: time.Now().Add(time.Minute), ApprovedBy: "somchai@example.com"}
	if err := db.SaveCode(ctx, code); err != nil {
		t.Fatal(err)
	}
	if err := db.RemoveMember(ctx, "somchai@example.com", 1); err != nil {
		t.Fatal(err)
	}

	// Act
	_, takeErr := db.TakeCode(ctx, "h")
	_, _, grantErr := db.CreateGrant(ctx, Grant{AccountID: 1, ClientID: "c", ClientName: "x", CanWrite: true,
		ApprovedBy: "somchai@example.com", RefreshExpiresAt: time.Now().Add(time.Hour)}, "h", "r1", time.Hour)

	// Assert
	if takeErr == nil {
		t.Error("the pending code still worked after removal")
	}
	if !errors.Is(grantErr, ErrNotFound) {
		t.Errorf("grant for a removed member: %v, want ErrNotFound", grantErr)
	}
}

func TestPostgres_DowngradeDisconnectsWriteApps(t *testing.T) {
	// Arrange
	db := openDB(t)
	ctx := context.Background()
	tokens := &mcp.Postgres{Pool: db.Pool}
	if err := db.AddMember(ctx, Member{Email: "nok@example.com", AccountID: 1, CanWrite: true}); err != nil {
		t.Fatal(err)
	}
	_, writeTok, err := db.CreateGrant(ctx, Grant{AccountID: 1, ClientID: "c", ClientName: "x", CanWrite: true, ApprovedBy: "nok@example.com",
		RefreshExpiresAt: time.Now().Add(time.Hour)}, "c1", "r1", time.Hour)
	if err != nil {
		t.Fatal(err)
	}
	_, readTok, err := db.CreateGrant(ctx, Grant{AccountID: 1, ClientID: "c", ClientName: "x", ApprovedBy: "nok@example.com",
		RefreshExpiresAt: time.Now().Add(time.Hour)}, "c2", "r2", time.Hour)
	if err != nil {
		t.Fatal(err)
	}

	// Act
	downErr := db.AddMember(ctx, Member{Email: "nok@example.com", AccountID: 1, CanWrite: false})
	_, w := tokens.Lookup(ctx, writeTok)
	_, r := tokens.Lookup(ctx, readTok)
	_, _, newWrite := db.CreateGrant(ctx, Grant{AccountID: 1, ClientID: "c", ClientName: "x", CanWrite: true, ApprovedBy: "nok@example.com",
		RefreshExpiresAt: time.Now().Add(time.Hour)}, "c3", "r3", time.Hour)

	// Assert
	if downErr != nil || !errors.Is(w, mcp.ErrInvalidToken) || r != nil || !errors.Is(newWrite, ErrNotFound) {
		t.Fatalf("down=%v writeTok=%v readTok=%v newWrite=%v", downErr, w, r, newWrite)
	}
}

func TestPostgres_PasswordGrantsReadBackWithoutApprover(t *testing.T) {
	// Arrange: a grant made by the admin password (no approver), e.g. from v6.
	db := openDB(t)
	ctx := context.Background()
	if _, _, err := db.CreateGrant(ctx, Grant{AccountID: 1, ClientID: "c", ClientName: "x", RefreshExpiresAt: time.Now().Add(time.Hour)}, "c", "r1", time.Hour); err != nil {
		t.Fatal(err)
	}

	// Act
	grants, err := db.Grants(ctx, 1)
	g, _, refreshErr := db.Refresh(ctx, "r1", "r2", "c", time.Now().Add(time.Hour), time.Hour)

	// Assert
	if err != nil || refreshErr != nil || len(grants) != 1 || grants[0].ApprovedBy != "" || g.ApprovedBy != "" {
		t.Fatalf("grants=%+v err=%v refresh=%v", grants, err, refreshErr)
	}
}
