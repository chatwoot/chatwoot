package knowledge

import (
	"context"
	"errors"
	"os"
	"testing"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/embed"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/profile"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Integration test: set TEST_DATABASE_URL to an empty scratch database with
// pgvector available, e.g. postgres://postgres:...@localhost:5432/ai_service_test.
// The test drops and recreates the kb_* and business_profiles tables.
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
	if _, err := pool.Exec(ctx, "DROP TABLE IF EXISTS kb_chunks, kb_documents, business_profiles, kb_schema_version"); err != nil {
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

// Schema v2 creates business_profiles; the profile store reads and writes it.
func TestPostgres_BusinessProfileRoundTrip(t *testing.T) {
	// Arrange
	db := openTestDB(t)
	store := &profile.Postgres{Pool: db.Pool}
	ctx := context.Background()

	// Act: an unknown account reads as empty, then save twice (upsert).
	empty, errEmpty := store.Get(ctx, 7)
	errFirst := store.Save(ctx, profile.Profile{AccountID: 7, BusinessName: "First", Rules: "ห้ามให้ส่วนลด", Features: profile.Features{Voice: true, Stickers: true}})
	errSecond := store.Save(ctx, profile.Profile{AccountID: 7, BusinessName: "Johnstocker AI Studio", About: "คอร์สออนไลน์"})
	errInvalid := store.Save(ctx, profile.Profile{AccountID: 0, BusinessName: "x"})
	got, errGet := store.Get(ctx, 7)
	other, _ := store.Get(ctx, 8)

	// Assert
	for _, err := range []error{errEmpty, errFirst, errSecond, errGet} {
		if err != nil {
			t.Fatal(err)
		}
	}
	if !empty.Empty() || empty.AccountID != 7 {
		t.Errorf("unknown account = %+v, want an empty profile for account 7", empty)
	}
	if errInvalid == nil {
		t.Error("saving account 0 succeeded, want a validation error")
	}
	if got.BusinessName != "Johnstocker AI Studio" || got.About != "คอร์สออนไลน์" || got.Rules != "" || got.UpdatedAt.IsZero() ||
		got.Features != (profile.Features{}) {
		t.Errorf("after upsert = %+v", got)
	}
	if !other.Empty() {
		t.Errorf("account 8 = %+v, want empty (profiles are per account)", other)
	}
}

// Production databases are at schema v1; Migrate must add business_profiles
// without touching existing knowledge.
func TestPostgres_MigratesV1ToV2(t *testing.T) {
	// Arrange: a v1 database holding one document.
	db := openTestDB(t)
	ctx := context.Background()
	if _, err := db.Pool.Exec(ctx, `DROP TABLE business_profiles;
		UPDATE kb_schema_version SET version = 1;
		INSERT INTO kb_documents (account_id, kind, title, content) VALUES (1, 'faq', 'q', 'a');`); err != nil {
		t.Fatal(err)
	}

	// Act
	err := db.Migrate(ctx)

	// Assert
	if err != nil {
		t.Fatalf("Migrate: %v", err)
	}
	var version, docs int
	var table *string
	if err := db.Pool.QueryRow(ctx, `SELECT (SELECT version FROM kb_schema_version), (SELECT count(*) FROM kb_documents),
		to_regclass('business_profiles')::text`).Scan(&version, &docs, &table); err != nil {
		t.Fatal(err)
	}
	if version != 3 || docs != 1 || table == nil {
		t.Errorf("version=%d docs=%d business_profiles=%v, want 3, 1, present", version, docs, table)
	}
	var rls bool
	if err := db.Pool.QueryRow(ctx, "SELECT relrowsecurity FROM pg_class WHERE relname = 'business_profiles'").Scan(&rls); err != nil {
		t.Fatal(err)
	}
	if !rls {
		t.Error("row level security is off on business_profiles")
	}
	// Supabase API roles exist only on Supabase; elsewhere there is nothing to revoke.
	var exposed bool
	if err := db.Pool.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM pg_roles r WHERE r.rolname IN ('anon', 'authenticated')
		AND has_table_privilege(r.rolname, 'business_profiles', 'SELECT'))`).Scan(&exposed); err != nil {
		t.Fatal(err)
	}
	if exposed {
		t.Error("anon or authenticated can read business_profiles")
	}
}

// Production is at schema v2 with saved profiles; v3 adds feature switches,
// all off, without touching the saved text.
func TestPostgres_MigratesV2ToV3FeaturesOff(t *testing.T) {
	// Arrange: a v2 database holding one profile.
	db := openTestDB(t)
	ctx := context.Background()
	if _, err := db.Pool.Exec(ctx, `ALTER TABLE business_profiles DROP COLUMN voice_enabled, DROP COLUMN images_enabled, DROP COLUMN stickers_enabled;
		UPDATE kb_schema_version SET version = 2;
		INSERT INTO business_profiles (account_id, business_name) VALUES (1, 'Johnstocker AI Studio');`); err != nil {
		t.Fatal(err)
	}

	// Act
	err := db.Migrate(ctx)
	got, getErr := (&profile.Postgres{Pool: db.Pool}).Get(ctx, 1)

	// Assert
	if err != nil || getErr != nil {
		t.Fatalf("migrate %v, get %v", err, getErr)
	}
	if got.BusinessName != "Johnstocker AI Studio" || got.Features != (profile.Features{}) {
		t.Errorf("after v3 = %+v, want the saved name and every feature off", got)
	}
	var rls, exposed bool
	if err := db.Pool.QueryRow(ctx, `SELECT relrowsecurity FROM pg_class WHERE relname = 'business_profiles'`).Scan(&rls); err != nil || !rls {
		t.Errorf("row level security must stay on after v3 (err %v)", err)
	}
	if err := db.Pool.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM pg_roles r WHERE r.rolname IN ('anon', 'authenticated')
		AND has_table_privilege(r.rolname, 'business_profiles', 'SELECT'))`).Scan(&exposed); err != nil || exposed {
		t.Errorf("anon/authenticated must not read business_profiles after v3 (err %v)", err)
	}
}

// Rolling back to the v2 binary must not clear switches the v3 binary saved:
// its upsert (copied from develop 9a4b1f3) does not touch the new columns.
func TestPostgres_OldBinarySaveKeepsFeatureSwitches(t *testing.T) {
	// Arrange
	db := openTestDB(t)
	ctx := context.Background()
	store := &profile.Postgres{Pool: db.Pool}
	if err := store.Save(ctx, profile.Profile{AccountID: 1, BusinessName: "A", Features: profile.Features{Voice: true}}); err != nil {
		t.Fatal(err)
	}

	// Act: the v2 binary's Save statement.
	_, err := db.Pool.Exec(ctx, `INSERT INTO business_profiles
		(account_id, business_name, about, tone, contact, rules, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, now())
		ON CONFLICT (account_id) DO UPDATE SET business_name = EXCLUDED.business_name,
		about = EXCLUDED.about, tone = EXCLUDED.tone, contact = EXCLUDED.contact,
		rules = EXCLUDED.rules, updated_at = now()`, 1, "B", "", "", "", "")
	got, getErr := store.Get(ctx, 1)

	// Assert
	if err != nil || getErr != nil || got.BusinessName != "B" || !got.Features.Voice {
		t.Errorf("after an old-binary save: %+v (err %v / %v), want name B and voice still on", got, err, getErr)
	}
}
