package knowledge

import (
	"context"
	"errors"
	"os"
	"strings"
	"testing"
	"time"

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
	if _, err := pool.Exec(ctx, "DROP TABLE IF EXISTS kb_chunks, kb_documents, business_profiles, kb_audit, mcp_tokens, oauth_codes, oauth_grants, oauth_clients, team_members, admin_events, web_sources, chatwoot_inboxes, ai_pending_changes, fb_comments, kb_schema_version"); err != nil {
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

	read, _ := p.Get(ctx, 1, id)

	// Act
	err = p.ReplaceChunks(ctx, read, "m1", []Chunk{{Content: "new", Embedding: axis(2)}})
	missing := p.ReplaceChunks(ctx, Document{ID: id + 999, AccountID: 1}, "m1", nil)
	otherAcct := p.ReplaceChunks(ctx, Document{ID: id, AccountID: 2, UpdatedAt: read.UpdatedAt}, "m1", nil)

	// Assert
	if err != nil || !errors.Is(missing, ErrNotFound) || !errors.Is(otherAcct, ErrNotFound) {
		t.Fatalf("err=%v missing=%v otherAcct=%v", err, missing, otherAcct)
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
	if version != SchemaVersion || docs != 1 || table == nil {
		t.Errorf("version=%d docs=%d business_profiles=%v, want %d, 1, present", version, docs, table, SchemaVersion)
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

// Production will be at schema v3 with documents; v4 adds validity dates and
// usage counters without changing what the bot finds.
func TestPostgres_MigratesV3ToV4KeepsDocumentsActive(t *testing.T) {
	// Arrange: a v3 database holding one document with a chunk.
	db := openTestDB(t)
	ctx := context.Background()
	if _, err := db.Pool.Exec(ctx, `ALTER TABLE kb_documents DROP COLUMN valid_from, DROP COLUMN valid_until,
		DROP COLUMN use_count, DROP COLUMN last_used_at;
		UPDATE kb_schema_version SET version = 3;`); err != nil {
		t.Fatal(err)
	}
	if _, err := db.Pool.Exec(ctx, `INSERT INTO kb_documents (account_id, kind, title, content) VALUES (1, 'faq', 'q', 'a')`); err != nil {
		t.Fatal(err)
	}
	var docID int64
	if err := db.Pool.QueryRow(ctx, "SELECT id FROM kb_documents").Scan(&docID); err != nil {
		t.Fatal(err)
	}
	if _, err := db.Pool.Exec(ctx, `INSERT INTO kb_chunks (document_id, account_id, ord, content, embedding_model, embedding)
		VALUES ($1, 1, 0, 'q a', 'm', $2::vector)`, docID, vectorLiteral(axis(0))); err != nil {
		t.Fatal(err)
	}

	// Act
	err := db.Migrate(ctx)
	hits, searchErr := db.Search(ctx, Query{AccountID: 1, Model: "m", Vector: axis(0), Limit: 3})
	docs, listErr := db.List(ctx, 1, "m")

	// Assert
	if err != nil || searchErr != nil || listErr != nil {
		t.Fatalf("migrate %v, search %v, list %v", err, searchErr, listErr)
	}
	var version int
	if err := db.Pool.QueryRow(ctx, "SELECT version FROM kb_schema_version").Scan(&version); err != nil || version != SchemaVersion {
		t.Fatalf("version = %d (err %v), want %d", version, err, SchemaVersion)
	}
	if len(hits) != 1 || len(docs) != 1 || docs[0].UseCount != 0 || !docs[0].ValidUntil.IsZero() || !docs[0].LastUsedAt.IsZero() {
		t.Errorf("after v4: hits=%d docs=%+v", len(hits), docs)
	}
}

func TestPostgres_ValidityWindowHidesDocumentsFromTheBot(t *testing.T) {
	// Arrange
	db := openTestDB(t)
	ctx := context.Background()
	now := time.Now()
	add := func(title string, from, until time.Time, dim int) {
		t.Helper()
		d := Document{AccountID: 1, Kind: KindFAQ, Title: title, Content: "x", ValidFrom: from, ValidUntil: until}
		if _, err := db.Insert(ctx, d, "m", []Chunk{{Content: title, Embedding: axis(dim)}}); err != nil {
			t.Fatal(err)
		}
	}
	add("open", time.Time{}, time.Time{}, 0)
	add("expired", now.Add(-48*time.Hour), now.Add(-time.Hour), 1)
	add("scheduled", now.Add(time.Hour), time.Time{}, 2)
	add("current", now.Add(-time.Hour), now.Add(time.Hour), 3)
	titles := func(inactive bool) map[string]bool {
		got := map[string]bool{}
		for dim := 0; dim < 4; dim++ {
			hits, err := db.Search(ctx, Query{AccountID: 1, Model: "m", Vector: axis(dim), Limit: 1, IncludeInactive: inactive})
			if err != nil {
				t.Fatal(err)
			}
			for _, h := range hits {
				if h.Score > 0.99 {
					got[h.Title] = true
				}
			}
		}
		return got
	}

	// Act
	bot, all := titles(false), titles(true)

	// Assert
	if !bot["open"] || !bot["current"] || bot["expired"] || bot["scheduled"] {
		t.Errorf("bot sees %v, want only open and current", bot)
	}
	if len(all) != 4 {
		t.Errorf("duplicate check sees %v, want all four", all)
	}
}

func TestPostgres_UpdateGetAndMarkUsed(t *testing.T) {
	// Arrange
	db := openTestDB(t)
	ctx := context.Background()
	id, err := db.Insert(ctx, Document{AccountID: 1, Kind: KindFAQ, Title: "old", Content: "a"}, "m",
		[]Chunk{{Content: "old", Embedding: axis(0)}})
	if err != nil {
		t.Fatal(err)
	}
	until := time.Date(2030, 1, 1, 0, 0, 0, 0, time.UTC)

	// Act
	upErr := db.Update(ctx, Document{ID: id, AccountID: 1, InboxID: 5, Kind: KindFAQ, Title: "new", Content: "b", ValidUntil: until},
		"m", []Chunk{{Content: "new", Embedding: axis(1)}, {Ord: 1, Content: "new 2", Embedding: axis(2)}})
	wrongAcct := db.Update(ctx, Document{ID: id, AccountID: 2, Kind: KindFAQ, Title: "hijack", Content: "c"}, "m", nil)
	usedErr := db.MarkUsed(ctx, 1, []int64{id})
	_ = db.MarkUsed(ctx, 2, []int64{id}) // other account: no effect
	got, getErr := db.Get(ctx, 1, id)
	_, otherErr := db.Get(ctx, 2, id)
	hits, _ := db.Search(ctx, Query{AccountID: 1, InboxID: 5, Model: "m", Vector: axis(1), Limit: 5})

	// Assert
	if upErr != nil || usedErr != nil || getErr != nil {
		t.Fatalf("update %v, used %v, get %v", upErr, usedErr, getErr)
	}
	if !errors.Is(wrongAcct, ErrNotFound) || !errors.Is(otherErr, ErrNotFound) {
		t.Errorf("other account: update %v, get %v, want ErrNotFound", wrongAcct, otherErr)
	}
	if got.Title != "new" || got.InboxID != 5 || !got.ValidUntil.Equal(until) || got.UseCount != 1 || got.LastUsedAt.IsZero() {
		t.Errorf("after update = %+v", got)
	}
	if len(hits) != 2 || hits[0].Title != "new" {
		t.Errorf("chunks not replaced: %+v", hits)
	}
}

// A re-index that read a document before an admin edited it must not write
// chunks of the old text over the edit.
func TestPostgres_ReplaceChunksSkipsEditedDocument(t *testing.T) {
	// Arrange
	db := openTestDB(t)
	ctx := context.Background()
	id, err := db.Insert(ctx, Document{AccountID: 1, Kind: KindFAQ, Title: "old", Content: "a"}, "m",
		[]Chunk{{Content: "old", Embedding: axis(0)}})
	if err != nil {
		t.Fatal(err)
	}
	stale, _ := db.Get(ctx, 1, id) // re-index reads here...
	if err := db.Update(ctx, Document{ID: id, AccountID: 1, Kind: KindFAQ, Title: "new", Content: "b"}, "m",
		[]Chunk{{Content: "new", Embedding: axis(1)}}); err != nil { // ...admin edits...
		t.Fatal(err)
	}

	// Act: ...then re-index writes chunks of the old text.
	err = db.ReplaceChunks(ctx, stale, "m", []Chunk{{Content: "old", Embedding: axis(0)}})
	hits, _ := db.Search(ctx, Query{AccountID: 1, Model: "m", Vector: axis(1), Limit: 5})

	// Assert
	if !errors.Is(err, ErrChanged) {
		t.Fatalf("err = %v, want ErrChanged", err)
	}
	if len(hits) != 1 || hits[0].Content != "new" {
		t.Errorf("chunks after = %+v, want only the edited text", hits)
	}
}

// The validity filter must hold when the planner uses the HNSW index with
// iterative scans (small tables otherwise get a sequential scan): expired
// documents nearest to the query must be skipped, not returned or starve
// the result.
func TestPostgres_ValidityFilterThroughHNSWIndex(t *testing.T) {
	// Arrange: 30 expired documents right next to the query, 1 active further away.
	db := openTestDB(t)
	ctx := context.Background()
	past := time.Now().Add(-time.Hour)
	near := func(i int) []float32 {
		v := axis(0)
		v[1+i] = 0.01
		return v
	}
	for i := 0; i < 30; i++ {
		if _, err := db.Insert(ctx, Document{AccountID: 1, Kind: KindFAQ, Title: "expired", Content: "x", ValidUntil: past},
			"m", []Chunk{{Content: "expired", Embedding: near(i)}}); err != nil {
			t.Fatal(err)
		}
	}
	active := axis(0)
	active[100] = 0.5
	if _, err := db.Insert(ctx, Document{AccountID: 1, Kind: KindFAQ, Title: "active", Content: "x"},
		"m", []Chunk{{Content: "active", Embedding: active}}); err != nil {
		t.Fatal(err)
	}
	tx, err := db.Pool.Begin(ctx)
	if err != nil {
		t.Fatal(err)
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	if _, err := tx.Exec(ctx, "SET LOCAL enable_seqscan = off; SET LOCAL enable_sort = off; SET LOCAL hnsw.iterative_scan = relaxed_order"); err != nil {
		t.Fatal(err)
	}
	const q = `SELECT d.title FROM kb_chunks c JOIN kb_documents d ON d.id = c.document_id
		WHERE c.account_id = $2 AND (c.inbox_id IS NULL OR c.inbox_id = $3) AND c.embedding_model = $4
		  AND ($6 OR ((d.valid_from IS NULL OR d.valid_from <= now()) AND (d.valid_until IS NULL OR d.valid_until > now())))
		ORDER BY c.embedding <=> $1::vector LIMIT $5`
	args := []any{vectorLiteral(axis(0)), int64(1), int64(0), "m", 3, false}

	// Act
	var plan strings.Builder
	rows, err := tx.Query(ctx, "EXPLAIN "+q, args...)
	if err != nil {
		t.Fatal(err)
	}
	for rows.Next() {
		var line string
		_ = rows.Scan(&line)
		plan.WriteString(line + "\n")
	}
	rows.Close()
	var titles []string
	rows, err = tx.Query(ctx, q, args...)
	if err != nil {
		t.Fatal(err)
	}
	for rows.Next() {
		var title string
		_ = rows.Scan(&title)
		titles = append(titles, title)
	}
	rows.Close()

	// Assert
	if !strings.Contains(plan.String(), "kb_chunks_embedding") {
		t.Fatalf("plan does not use the HNSW index:\n%s", plan.String())
	}
	if len(titles) != 1 || titles[0] != "active" {
		t.Errorf("titles = %v, want only the active document", titles)
	}
}

// Production may jump from v2 to v4 in one Migrate call.
func TestPostgres_MigratesV2ToLatestInOneStep(t *testing.T) {
	// Arrange: a v2 database with a document and a profile.
	db := openTestDB(t)
	ctx := context.Background()
	if _, err := db.Pool.Exec(ctx, `DROP TABLE chatwoot_inboxes, web_sources, admin_events, team_members, oauth_codes, oauth_grants, oauth_clients, mcp_tokens, kb_audit;
		DROP INDEX kb_documents_source_key_idx;
		ALTER TABLE kb_documents DROP CONSTRAINT kb_documents_source_key_check, DROP COLUMN source_key;
		ALTER TABLE business_profiles DROP COLUMN voice_enabled, DROP COLUMN images_enabled, DROP COLUMN stickers_enabled;
		ALTER TABLE kb_documents DROP COLUMN valid_from, DROP COLUMN valid_until, DROP COLUMN use_count, DROP COLUMN last_used_at;
		UPDATE kb_schema_version SET version = 2;
		INSERT INTO business_profiles (account_id, business_name) VALUES (1, 'A');
		INSERT INTO kb_documents (account_id, kind, title, content) VALUES (1, 'faq', 'q', 'a');`); err != nil {
		t.Fatal(err)
	}

	// Act
	err := db.Migrate(ctx)

	// Assert
	if err != nil {
		t.Fatalf("Migrate: %v", err)
	}
	var version, cols int
	if err := db.Pool.QueryRow(ctx, `SELECT (SELECT version FROM kb_schema_version),
		(SELECT count(*) FROM information_schema.columns WHERE
		  (table_name = 'business_profiles' AND column_name IN ('voice_enabled', 'images_enabled', 'stickers_enabled')) OR
		  (table_name = 'kb_documents' AND column_name IN ('valid_from', 'valid_until', 'use_count', 'last_used_at')))`).Scan(&version, &cols); err != nil {
		t.Fatal(err)
	}
	var objects int
	if err := db.Pool.QueryRow(ctx, `SELECT (to_regclass('kb_audit') IS NOT NULL)::int + (to_regclass('mcp_tokens') IS NOT NULL)::int
		+ (to_regclass('kb_documents_source_key_idx') IS NOT NULL)::int
		+ (SELECT count(*) FROM information_schema.columns WHERE table_name = 'kb_documents' AND column_name = 'source_key')::int`).Scan(&objects); err != nil {
		t.Fatal(err)
	}
	if objects != 4 {
		t.Errorf("v5 objects present = %d, want 4 (kb_audit, mcp_tokens, key index, source_key)", objects)
	}
	var v6 int
	if err := db.Pool.QueryRow(ctx, `SELECT (to_regclass('oauth_clients') IS NOT NULL)::int + (to_regclass('oauth_codes') IS NOT NULL)::int
		+ (to_regclass('oauth_grants') IS NOT NULL)::int + (to_regclass('mcp_tokens_grant_idx') IS NOT NULL)::int
		+ (SELECT count(*) FROM pg_constraint WHERE conrelid = 'mcp_tokens'::regclass AND contype = 'f' AND confdeltype = 'c')::int
		+ (SELECT count(*) FROM pg_class WHERE relname IN ('oauth_clients', 'oauth_codes', 'oauth_grants') AND relrowsecurity)::int`).Scan(&v6); err != nil {
		t.Fatal(err)
	}
	if v6 != 8 {
		t.Errorf("v6 objects present = %d, want 8 (3 tables, grant index, cascade FK, RLS on 3)", v6)
	}
	var v7 int
	if err := db.Pool.QueryRow(ctx, `SELECT (to_regclass('team_members') IS NOT NULL)::int
		+ (SELECT count(*) FROM information_schema.columns WHERE column_name = 'approved_by' AND table_name IN ('oauth_grants', 'oauth_codes') AND table_schema = current_schema())::int
		+ (SELECT count(*) FROM pg_class WHERE relname = 'team_members' AND relrowsecurity)::int`).Scan(&v7); err != nil {
		t.Fatal(err)
	}
	if v7 != 4 {
		t.Errorf("v7 objects present = %d, want 4 (team_members, 2 approved_by, RLS)", v7)
	}
	var v8 int
	if err := db.Pool.QueryRow(ctx, `SELECT (to_regclass('admin_events') IS NOT NULL)::int
		+ (to_regclass('admin_events_account_idx') IS NOT NULL)::int
		+ (SELECT count(*) FROM pg_class WHERE relname = 'admin_events' AND relrowsecurity)::int`).Scan(&v8); err != nil {
		t.Fatal(err)
	}
	if v8 != 3 {
		t.Errorf("v8 objects present = %d, want 3 (admin_events, index, RLS)", v8)
	}
	var v9 int
	if err := db.Pool.QueryRow(ctx, `SELECT (to_regclass('web_sources') IS NOT NULL)::int
		+ (SELECT count(*) FROM pg_class WHERE relname = 'web_sources' AND relrowsecurity)::int`).Scan(&v9); err != nil {
		t.Fatal(err)
	}
	if v9 != 2 {
		t.Errorf("v9 objects present = %d, want 2 (web_sources, RLS)", v9)
	}
	var v10 int
	if err := db.Pool.QueryRow(ctx, `SELECT (to_regclass('chatwoot_inboxes') IS NOT NULL)::int
		+ (SELECT count(*) FROM pg_class WHERE relname = 'chatwoot_inboxes' AND relrowsecurity)::int`).Scan(&v10); err != nil {
		t.Fatal(err)
	}
	if v10 != 2 {
		t.Errorf("v10 objects present = %d, want 2 (chatwoot_inboxes, RLS)", v10)
	}
	var v11 int
	if err := db.Pool.QueryRow(ctx, `SELECT count(*) FROM information_schema.columns
		WHERE table_name = 'web_sources' AND column_name IN ('kind', 'item_count')`).Scan(&v11); err != nil {
		t.Fatal(err)
	}
	if v11 != 2 {
		t.Errorf("v11 columns present = %d, want 2 (kind, item_count)", v11)
	}
	docs, _ := db.List(ctx, 1, "m")
	if len(docs) == 1 && docs[0].SourceKey != "" {
		t.Errorf("existing document got a key: %q", docs[0].SourceKey)
	}
	if version != SchemaVersion || cols != 7 || len(docs) != 1 || docs[0].Status(time.Now()) != StatusActive {
		t.Errorf("version=%d new columns=%d docs=%+v, want %d, 7, one active document", version, cols, docs, SchemaVersion)
	}
}

func TestPostgres_SourceKeyUniquePerAccount(t *testing.T) {
	// Arrange
	db := openTestDB(t)
	ctx := context.Background()
	add := func(acct int64, key string) error {
		_, err := db.Insert(ctx, Document{AccountID: acct, Kind: KindFAQ, Title: "q", Content: "a", SourceKey: key}, "m",
			[]Chunk{{Content: "q", Embedding: axis(0)}})
		return err
	}

	// Act
	first, dup, otherAcct, noKey1, noKey2 := add(1, "product-017"), add(1, "product-017"), add(2, "product-017"), add(1, ""), add(1, "")
	got, getErr := db.GetByKey(ctx, 1, "product-017")
	_, missing := db.GetByKey(ctx, 3, "product-017")

	// Assert
	if first != nil || dup == nil || otherAcct != nil || noKey1 != nil || noKey2 != nil {
		t.Fatalf("first=%v dup=%v otherAcct=%v noKey=%v/%v", first, dup, otherAcct, noKey1, noKey2)
	}
	if getErr != nil || got.SourceKey != "product-017" || got.AccountID != 1 || !errors.Is(missing, ErrNotFound) {
		t.Errorf("get=%+v err=%v missing=%v", got, getErr, missing)
	}
}

func TestPostgres_UpdateKeepsSourceKeyAndOldBinaryWorks(t *testing.T) {
	// Arrange
	db := openTestDB(t)
	ctx := context.Background()
	id, err := db.Insert(ctx, Document{AccountID: 1, Kind: KindFAQ, Title: "q", Content: "a", SourceKey: "product-017"}, "m",
		[]Chunk{{Content: "q", Embedding: axis(0)}})
	if err != nil {
		t.Fatal(err)
	}

	// Act: an admin edit (no key in the form), then the v4 binary's statements.
	upErr := db.Update(ctx, Document{ID: id, AccountID: 1, Kind: KindFAQ, Title: "q2", Content: "b"}, "m",
		[]Chunk{{Content: "q2", Embedding: axis(1)}})
	_, oldInsert := db.Pool.Exec(ctx, `INSERT INTO kb_documents (account_id, inbox_id, kind, title, content, valid_from, valid_until)
		VALUES (1, NULL, 'faq', 'old binary', 'x', NULL, NULL)`)
	rows, oldSelect := db.Pool.Query(ctx, `SELECT d.id, d.account_id, COALESCE(d.inbox_id, 0), d.kind, d.title, d.content, d.updated_at,
		d.valid_from, d.valid_until, d.use_count, d.last_used_at FROM kb_documents d WHERE d.account_id = 1`)
	if oldSelect == nil {
		rows.Close()
	}
	got, _ := db.Get(ctx, 1, id)

	// Assert
	if upErr != nil || oldInsert != nil || oldSelect != nil {
		t.Fatalf("update %v, old insert %v, old select %v", upErr, oldInsert, oldSelect)
	}
	if got.SourceKey != "product-017" || got.Title != "q2" {
		t.Errorf("after edit = %+v, want the key kept", got)
	}
}

func TestPostgres_DatabaseRefusesBadKeys(t *testing.T) {
	// Arrange
	db := openTestDB(t)
	ctx := context.Background()
	bad := []string{"", "has space", "tab\there", strings.Repeat("k", 501)}

	for _, k := range bad {
		// Act
		_, err := db.Pool.Exec(ctx, `INSERT INTO kb_documents (account_id, kind, title, content, source_key) VALUES (1, 'faq', 'q', 'a', $1)`, k)

		// Assert
		if err == nil {
			t.Errorf("key %q accepted", k)
		}
	}
}

func TestPostgres_ConcurrentSameNewKeyBecomesUpdate(t *testing.T) {
	// Arrange: the key appears between the service's lookup and its insert.
	db := openTestDB(t)
	ctx := context.Background()
	if _, err := db.Insert(ctx, Document{AccountID: 1, Kind: KindFAQ, Title: "first", Content: "a", SourceKey: "k"}, "m",
		[]Chunk{{Content: "first", Embedding: axis(0)}}); err != nil {
		t.Fatal(err)
	}

	// Act
	_, err := db.Insert(ctx, Document{AccountID: 1, Kind: KindFAQ, Title: "second", Content: "b", SourceKey: "k"}, "m",
		[]Chunk{{Content: "second", Embedding: axis(1)}})

	// Assert
	if !errors.Is(err, ErrKeyTaken) {
		t.Fatalf("err = %v, want ErrKeyTaken", err)
	}
}

func TestPostgres_SimilarNeverSeesOtherAccounts(t *testing.T) {
	// Arrange
	db := openTestDB(t)
	ctx := context.Background()
	if _, err := db.Insert(ctx, Document{AccountID: 2, Kind: KindFAQ, Title: "secret price", Content: "x"}, "m",
		[]Chunk{{Content: "secret", Embedding: axis(0)}}); err != nil {
		t.Fatal(err)
	}

	// Act
	hits, err := db.Search(ctx, Query{AccountID: 1, Model: "m", Vector: axis(0), Limit: 8, IncludeInactive: true})

	// Assert
	if err != nil || len(hits) != 0 {
		t.Fatalf("hits=%+v err=%v", hits, err)
	}
}

func TestPostgres_ListByKeyPrefixStaysInAccountAndFeed(t *testing.T) {
	// Arrange
	db := openTestDB(t)
	ctx := context.Background()
	for _, d := range []Document{
		{AccountID: 1, Kind: KindText, Title: "a", Content: "a", SourceKey: "feed:1:a"},
		{AccountID: 1, Kind: KindText, Title: "b", Content: "b", SourceKey: "feed:1:b"},
		{AccountID: 1, Kind: KindText, Title: "c", Content: "c", SourceKey: "feed:10:a"},
		{AccountID: 2, Kind: KindText, Title: "d", Content: "d", SourceKey: "feed:1:a"},
		{AccountID: 1, Kind: KindText, Title: "e", Content: "e", SourceKey: "product-001"},
		{AccountID: 1, Kind: KindText, Title: "f", Content: "f"},
	} {
		if _, err := db.Insert(ctx, d, "m", nil); err != nil {
			t.Fatal(err)
		}
	}

	// Act
	got, err := db.ListByKeyPrefix(ctx, 1, "feed:1:")
	pct, err2 := db.ListByKeyPrefix(ctx, 1, "%") // LIKE wildcards are plain text here

	// Assert
	if err != nil || err2 != nil || len(got) != 2 || got[0].SourceKey != "feed:1:a" || got[1].SourceKey != "feed:1:b" || len(pct) != 0 {
		t.Errorf("got=%+v pct=%d err=%v %v", got, len(pct), err, err2)
	}
}

func TestPostgres_V11ConstraintsAndOldBinaryInsert(t *testing.T) {
	// Arrange
	db := openTestDB(t)
	ctx := context.Background()

	// Act: the v10 binary inserts without kind or item_count.
	var kind string
	var items int
	oldErr := db.Pool.QueryRow(ctx, `INSERT INTO web_sources (account_id, url) VALUES (1, 'https://example.com/a')
		RETURNING kind, item_count`).Scan(&kind, &items)
	_, badKind := db.Pool.Exec(ctx, "INSERT INTO web_sources (account_id, url, kind) VALUES (1, 'https://example.com/b', 'rss')")
	_, negative := db.Pool.Exec(ctx, "INSERT INTO web_sources (account_id, url, item_count) VALUES (1, 'https://example.com/c', -1)")
	_, huge := db.Pool.Exec(ctx, "INSERT INTO web_sources (account_id, url, item_count) VALUES (1, 'https://example.com/d', 100001)")

	// Assert
	if oldErr != nil || kind != "page" || items != 0 {
		t.Errorf("old insert: err=%v kind=%q items=%d, want page and 0", oldErr, kind, items)
	}
	if badKind == nil || negative == nil || huge == nil {
		t.Errorf("constraints: kind=%v negative=%v huge=%v, want all refused", badKind, negative, huge)
	}
}

// v12 on a Supabase-like database: anon and authenticated exist and get every
// new table and sequence by default. The upgrade from v11 must create the
// pending-changes table with row level security on and both roles shut out.
func TestPostgres_V12UpgradeShutsOutAPIRoles(t *testing.T) {
	// Arrange
	db := openTestDB(t)
	ctx := context.Background()
	if _, err := db.Pool.Exec(ctx, `DO $$ BEGIN
			IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN CREATE ROLE anon NOLOGIN; END IF;
			IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN CREATE ROLE authenticated NOLOGIN; END IF;
		END $$;
		ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated;
		ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated;
		DROP TABLE ai_pending_changes;
		UPDATE kb_schema_version SET version = 11;`); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		_, _ = db.Pool.Exec(context.Background(), `ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM anon, authenticated;
			ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON SEQUENCES FROM anon, authenticated;`)
	})

	// Act
	err := db.Migrate(ctx)

	// Assert
	if err != nil {
		t.Fatal(err)
	}
	var version int
	var rls, tableOpen, seqOpen bool
	if err := db.Pool.QueryRow(ctx, `SELECT (SELECT version FROM kb_schema_version),
		(SELECT relrowsecurity FROM pg_class WHERE relname = 'ai_pending_changes'),
		EXISTS (SELECT 1 FROM pg_roles r WHERE r.rolname IN ('anon', 'authenticated')
			AND has_table_privilege(r.rolname, 'ai_pending_changes', 'SELECT,INSERT,UPDATE,DELETE')),
		EXISTS (SELECT 1 FROM pg_roles r WHERE r.rolname IN ('anon', 'authenticated')
			AND has_sequence_privilege(r.rolname, 'ai_pending_changes_id_seq', 'USAGE,SELECT,UPDATE'))`).Scan(&version, &rls, &tableOpen, &seqOpen); err != nil {
		t.Fatal(err)
	}
	if version != SchemaVersion || !rls || tableOpen || seqOpen {
		t.Fatalf("version=%d rls=%v table open=%v sequence open=%v", version, rls, tableOpen, seqOpen)
	}
}

// v13 on a Supabase-like database: the upgrade from v12 must create the page
// comments table with row level security on and anon/authenticated shut out,
// and refuse an unknown status or a second row for the same comment.
func TestMigrate_V13CommentsTableIsClosedAndChecked(t *testing.T) {
	// Arrange
	db := openTestDB(t)
	ctx := context.Background()
	if _, err := db.Pool.Exec(ctx, `DO $$ BEGIN
			IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN CREATE ROLE anon NOLOGIN; END IF;
			IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN CREATE ROLE authenticated NOLOGIN; END IF;
		END $$;
		ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated;
		ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated;
		DROP TABLE fb_comments;
		UPDATE kb_schema_version SET version = 12;`); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		_, _ = db.Pool.Exec(context.Background(), `ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM anon, authenticated;
			ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON SEQUENCES FROM anon, authenticated;`)
	})

	// Act
	err := db.Migrate(ctx)
	insert := func(commentID, status string) error {
		_, err := db.Pool.Exec(ctx, `INSERT INTO fb_comments (account_id, page_id, comment_id, from_id, created_at, status)
			VALUES (1, 'p', $1, 'u', now(), $2)`, commentID, status)
		return err
	}
	okErr, dupErr, badStatus := insert("c1", "new"), insert("c1", "new"), insert("c2", "posted")

	// Assert
	if err != nil {
		t.Fatal(err)
	}
	var version int
	var rls, tableOpen, seqOpen bool
	if err := db.Pool.QueryRow(ctx, `SELECT (SELECT version FROM kb_schema_version),
		(SELECT relrowsecurity FROM pg_class WHERE relname = 'fb_comments'),
		EXISTS (SELECT 1 FROM pg_roles r WHERE r.rolname IN ('anon', 'authenticated')
			AND has_table_privilege(r.rolname, 'fb_comments', 'SELECT,INSERT,UPDATE,DELETE')),
		EXISTS (SELECT 1 FROM pg_roles r WHERE r.rolname IN ('anon', 'authenticated')
			AND has_sequence_privilege(r.rolname, 'fb_comments_id_seq', 'USAGE,SELECT,UPDATE'))`).Scan(&version, &rls, &tableOpen, &seqOpen); err != nil {
		t.Fatal(err)
	}
	if version != 13 || !rls || tableOpen || seqOpen {
		t.Fatalf("version=%d rls=%v table open=%v sequence open=%v", version, rls, tableOpen, seqOpen)
	}
	if okErr != nil || dupErr == nil || badStatus == nil {
		t.Fatalf("insert ok=%v duplicate=%v bad status=%v", okErr, dupErr, badStatus)
	}
}
