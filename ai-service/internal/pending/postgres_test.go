package pending

import (
	"context"
	"encoding/json"
	"errors"
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
	if _, err := pool.Exec(ctx, "DROP TABLE IF EXISTS kb_chunks, kb_documents, business_profiles, kb_audit, mcp_tokens, oauth_codes, oauth_grants, oauth_clients, team_members, admin_events, web_sources, chatwoot_inboxes, ai_pending_changes, kb_schema_version"); err != nil {
		t.Fatal(err)
	}
	if err := (&knowledge.Postgres{Pool: pool}).Migrate(ctx); err != nil {
		t.Fatal(err)
	}
	return &Postgres{Pool: pool}
}

func profileChange(acct int64, fields map[string]string) Change {
	b, _ := json.Marshal(fields)
	return Change{AccountID: acct, Kind: KindProfile, Target: ProfileTarget, Proposed: b, Actor: "claude", TokenID: 7}
}

func TestPostgres_ProfileProposalsMergeAndBumpVersion(t *testing.T) {
	// Arrange
	db := openDB(t)
	ctx := context.Background()

	// Act
	id1, err1 := db.Propose(ctx, profileChange(1, map[string]string{"tone": "Warm.", "rules": "Old rule."}))
	id2, err2 := db.Propose(ctx, profileChange(1, map[string]string{"rules": "New rule."}))
	got, getErr := db.Get(ctx, 1, id1)

	// Assert
	if err1 != nil || err2 != nil || getErr != nil || id1 != id2 {
		t.Fatalf("ids %d %d, errs %v %v %v", id1, id2, err1, err2, getErr)
	}
	var fields map[string]string
	if err := json.Unmarshal(got.Proposed, &fields); err != nil || fields["tone"] != "Warm." || fields["rules"] != "New rule." {
		t.Fatalf("proposed = %s", got.Proposed)
	}
	if got.Version != 2 || got.Actor != "claude" || got.TokenID != 7 || got.Kind != KindProfile {
		t.Fatalf("change = %+v", got)
	}
}

func TestPostgres_DocumentProposalReplaces(t *testing.T) {
	// Arrange
	db := openDB(t)
	ctx := context.Background()
	doc := func(content string) Change {
		b, _ := json.Marshal(map[string]string{"title": "Hours", "content": content})
		return Change{AccountID: 1, Kind: KindDocument, Target: "hours", Proposed: b, Actor: "claude"}
	}

	// Act
	id, _ := db.Propose(ctx, doc("9 to 5, plus a field the newer one drops"))
	_, err := db.Propose(ctx, doc("10 to 6"))
	got, _ := db.Get(ctx, 1, id)

	// Assert
	var fields map[string]string
	_ = json.Unmarshal(got.Proposed, &fields)
	if err != nil || fields["content"] != "10 to 6" || got.Version != 2 {
		t.Fatalf("err=%v change=%+v", err, got)
	}
}

func TestPostgres_StaysInAccount(t *testing.T) {
	// Arrange
	db := openDB(t)
	ctx := context.Background()
	id, _ := db.Propose(ctx, profileChange(1, map[string]string{"tone": "Warm."}))

	// Act
	_, getErr := db.Get(ctx, 2, id)
	removeErr := db.Remove(ctx, 2, id, 1)
	list2, _ := db.List(ctx, 2)
	n1, _ := db.Count(ctx, 1)

	// Assert
	if !errors.Is(getErr, ErrNotFound) || !errors.Is(removeErr, ErrNotFound) || len(list2) != 0 || n1 != 1 {
		t.Fatalf("get=%v remove=%v list2=%d count1=%d", getErr, removeErr, len(list2), n1)
	}
}

func TestPostgres_RemoveNeedsTheVersionSeen(t *testing.T) {
	// Arrange: the owner opened version 1, then the app updated it.
	db := openDB(t)
	ctx := context.Background()
	id, _ := db.Propose(ctx, profileChange(1, map[string]string{"tone": "Warm."}))
	_, _ = db.Propose(ctx, profileChange(1, map[string]string{"tone": "Pay via our Facebook page."}))

	// Act
	stale := db.Remove(ctx, 1, id, 1)
	fresh := db.Remove(ctx, 1, id, 2)
	again := db.Remove(ctx, 1, id, 2)

	// Assert
	if !errors.Is(stale, ErrChanged) || fresh != nil || !errors.Is(again, ErrNotFound) {
		t.Fatalf("stale=%v fresh=%v again=%v", stale, fresh, again)
	}
}

func TestPostgres_CapPerAccount(t *testing.T) {
	// Arrange
	db := openDB(t)
	ctx := context.Background()
	doc := func(acct int64, key string) Change {
		return Change{AccountID: acct, Kind: KindDocument, Target: key, Proposed: json.RawMessage(`{}`), Actor: "claude"}
	}
	for i := range MaxPerAccount {
		if _, err := db.Propose(ctx, doc(1, string(rune('a'+i%26))+string(rune('a'+i/26)))); err != nil {
			t.Fatal(err)
		}
	}

	// Act
	_, full := db.Propose(ctx, doc(1, "one-more"))
	_, update := db.Propose(ctx, doc(1, "aa"))
	_, other := db.Propose(ctx, doc(2, "one-more"))

	// Assert
	if !errors.Is(full, ErrFull) || update != nil || other != nil {
		t.Fatalf("full=%v update=%v other=%v", full, update, other)
	}
}

func TestPostgres_UnknownKindRefused(t *testing.T) {
	// Arrange
	db := openDB(t)

	// Act
	_, err := db.Propose(context.Background(), Change{AccountID: 1, Kind: "settings", Target: "x", Proposed: json.RawMessage(`{}`)})

	// Assert
	if err == nil {
		t.Fatal("unknown kind accepted")
	}
}
