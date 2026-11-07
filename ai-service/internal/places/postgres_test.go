package places

import (
	"context"
	"os"
	"testing"

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
	if _, err := pool.Exec(ctx, "DROP TABLE IF EXISTS kb_chunks, kb_documents, business_profiles, kb_audit, mcp_tokens, oauth_codes, oauth_grants, oauth_clients, team_members, admin_events, web_sources, chatwoot_inboxes, kb_schema_version"); err != nil {
		t.Fatal(err)
	}
	if err := (&knowledge.Postgres{Pool: pool}).Migrate(ctx); err != nil {
		t.Fatal(err)
	}
	return &Postgres{Pool: pool}
}

func TestPostgres_RecordAccountsInboxes(t *testing.T) {
	// Arrange
	db := openDB(t)
	ctx := context.Background()
	if _, err := db.Pool.Exec(ctx, "INSERT INTO business_profiles (account_id, business_name) VALUES (1, 'Profile name'), (4, 'Only a profile')"); err != nil {
		t.Fatal(err)
	}

	// Act
	err1 := db.Record(ctx, 1, "Acme", 3, "Website")
	err2 := db.Record(ctx, 1, "", 3, "") // blank names keep the saved ones
	err3 := db.Record(ctx, 1, "Acme", 2, "LINE")
	err4 := db.Record(ctx, 2, "Other", 9, "Facebook")
	accounts, accErr := db.Accounts(ctx)
	inboxes, inbErr := db.Inboxes(ctx, 1)
	none, _ := db.Inboxes(ctx, 4)

	// Assert
	for _, err := range []error{err1, err2, err3, err4, accErr, inbErr} {
		if err != nil {
			t.Fatal(err)
		}
	}
	want := []Place{{1, "Acme"}, {2, "Other"}, {4, "Only a profile"}}
	if len(accounts) != len(want) {
		t.Fatalf("accounts = %+v, want %+v", accounts, want)
	}
	for i := range want {
		if accounts[i] != want[i] {
			t.Errorf("accounts[%d] = %+v, want %+v", i, accounts[i], want[i])
		}
	}
	if len(inboxes) != 2 || inboxes[0] != (Place{2, "LINE"}) || inboxes[1] != (Place{3, "Website"}) {
		t.Errorf("inboxes = %+v, want LINE (2) and Website (3)", inboxes)
	}
	if len(none) != 0 {
		t.Errorf("account 4 inboxes = %+v, want none", none)
	}
}

func TestPostgres_RecordRejectsBadIDs(t *testing.T) {
	// Arrange
	db := openDB(t)

	// Act
	err := db.Record(context.Background(), 0, "x", 1, "y")

	// Assert
	if err == nil {
		t.Error("account 0 accepted, want check violation")
	}
}
