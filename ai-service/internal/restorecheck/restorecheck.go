// Package restorecheck proves a database backup can be restored and used:
// after a restore into a scratch database it runs Migrate, then checks the
// vector extension, the schema version, every required table, minimum row
// counts and one vector query. It reports table names and counts only, never
// row content. Issue: DEV-Johnstocker/chatwoot#1
//
// The idea (separate integrity, completeness and restore gates) comes from the
// owner's project-reuse-toolkit backup-verification recipe; this is a fresh Go
// implementation, not copied code.
package restorecheck

import (
	"context"
	"errors"
	"fmt"
	"net"
	"regexp"
	"strconv"
	"strings"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

// RequiredTables are every table ai-service's schema creates. A restore that
// lacks one is incomplete.
var RequiredTables = []string{
	"admin_events",
	"ai_pending_changes",
	"business_profiles",
	"chatwoot_inboxes",
	"fb_comments",
	"kb_audit",
	"kb_chunks",
	"kb_documents",
	"kb_schema_version",
	"mcp_tokens",
	"oauth_clients",
	"oauth_codes",
	"oauth_grants",
	"team_members",
	"web_sources",
}

// Report is the outcome of one restore check. It holds counts, never content.
type Report struct {
	SchemaBefore  int              `json:"schema_before"`
	SchemaAfter   int              `json:"schema_after"`
	VectorSchema  string           `json:"vector_schema"`
	Tables        map[string]int64 `json:"tables"`
	VectorQueryOK bool             `json:"vector_query_ok"`
	Problems      []string         `json:"problems"`
}

// CheckLoopback refuses any database that is not on this machine. Migrate
// writes, so the check must never reach production by mistake. Errors never
// include the DSN, which carries the password.
func CheckLoopback(dsn string) error {
	if strings.TrimSpace(dsn) == "" {
		return errors.New("no database URL given")
	}
	cfg, err := pgconn.ParseConfig(dsn)
	if err != nil {
		return errors.New("database URL does not parse")
	}
	hosts := []string{cfg.Host}
	for _, fallback := range cfg.Fallbacks {
		hosts = append(hosts, fallback.Host)
	}
	for _, host := range hosts {
		if !isLoopback(host) {
			return fmt.Errorf("refusing host %q: the restore check runs only against a local scratch database", host)
		}
	}
	return nil
}

func isLoopback(host string) bool {
	if strings.HasPrefix(host, "/") || host == "localhost" {
		return true // Unix socket or this machine
	}
	ip := net.ParseIP(host)
	return ip != nil && ip.IsLoopback()
}

var minRowsEntry = regexp.MustCompile(`^([a-z_][a-z0-9_]*)=([0-9]+)$`)

// ParseMinRows reads "table=n,table=n" into a map. Only required tables count.
func ParseMinRows(s string) (map[string]int64, error) {
	mins := map[string]int64{}
	for _, part := range strings.Split(s, ",") {
		part = strings.TrimSpace(part)
		if part == "" {
			continue
		}
		m := minRowsEntry.FindStringSubmatch(part)
		if m == nil {
			return nil, fmt.Errorf("bad min-rows entry %q, want table=n", part)
		}
		if !isRequired(m[1]) {
			return nil, fmt.Errorf("min-rows names %q, which is not an ai-service table", m[1])
		}
		n, err := strconv.ParseInt(m[2], 10, 64)
		if err != nil {
			return nil, fmt.Errorf("bad min-rows count in %q", part)
		}
		mins[m[1]] = n
	}
	return mins, nil
}

func isRequired(table string) bool {
	for _, name := range RequiredTables {
		if name == table {
			return true
		}
	}
	return false
}

// Evaluate fills Problems from the report, the wanted schema version and the
// minimum row counts.
func (r *Report) Evaluate(wantVersion int, minRows map[string]int64) {
	r.Problems = nil
	if r.VectorSchema == "" {
		r.Problems = append(r.Problems, "vector extension missing")
	}
	if r.SchemaAfter != wantVersion {
		r.Problems = append(r.Problems, fmt.Sprintf("schema version %d after Migrate, want %d", r.SchemaAfter, wantVersion))
	}
	for _, name := range RequiredTables {
		count, ok := r.Tables[name]
		if !ok {
			r.Problems = append(r.Problems, "missing table "+name)
			continue
		}
		if min := minRows[name]; count < min {
			r.Problems = append(r.Problems, fmt.Sprintf("%s has %d rows, want at least %d", name, count, min))
		}
	}
	if r.Tables["kb_chunks"] > 0 && !r.VectorQueryOK {
		r.Problems = append(r.Problems, "vector query failed on kb_chunks")
	}
}

// Run migrates the restored database and measures it. The caller must have
// passed the DSN through CheckLoopback.
func Run(ctx context.Context, pool *pgxpool.Pool) (*Report, error) {
	r := &Report{Tables: map[string]int64{}}
	before, err := schemaVersion(ctx, pool)
	if err != nil {
		return nil, fmt.Errorf("read schema version: %w", err)
	}
	r.SchemaBefore = before
	if err := (&knowledge.Postgres{Pool: pool}).Migrate(ctx); err != nil {
		return nil, fmt.Errorf("migrate: %w", err)
	}
	if r.SchemaAfter, err = schemaVersion(ctx, pool); err != nil {
		return nil, fmt.Errorf("read schema version: %w", err)
	}
	if err := pool.QueryRow(ctx, `SELECT coalesce(max(n.nspname), '')
		FROM pg_extension e JOIN pg_namespace n ON n.oid = e.extnamespace
		WHERE e.extname = 'vector'`).Scan(&r.VectorSchema); err != nil {
		return nil, fmt.Errorf("read extensions: %w", err)
	}
	for _, name := range RequiredTables {
		count, found, err := countRows(ctx, pool, name)
		if err != nil {
			return nil, fmt.Errorf("count %s: %w", name, err)
		}
		if found {
			r.Tables[name] = count
		}
	}
	if r.Tables["kb_chunks"] > 0 {
		r.VectorQueryOK = vectorQuery(ctx, pool) == nil
	}
	return r, nil
}

// schemaVersion returns 0 when the database has no ai-service schema yet.
func schemaVersion(ctx context.Context, pool *pgxpool.Pool) (int, error) {
	var exists bool
	if err := pool.QueryRow(ctx, "SELECT to_regclass('public.kb_schema_version') IS NOT NULL").Scan(&exists); err != nil {
		return 0, err
	}
	if !exists {
		return 0, nil
	}
	var version int
	err := pool.QueryRow(ctx, "SELECT coalesce(max(version), 0) FROM kb_schema_version").Scan(&version)
	return version, err
}

func countRows(ctx context.Context, pool *pgxpool.Pool, table string) (int64, bool, error) {
	var exists bool
	if err := pool.QueryRow(ctx, "SELECT to_regclass($1) IS NOT NULL", "public."+table).Scan(&exists); err != nil || !exists {
		return 0, false, err
	}
	var count int64
	err := pool.QueryRow(ctx, "SELECT count(*) FROM public."+pgx.Identifier{table}.Sanitize()).Scan(&count)
	return count, true, err
}

// vectorQuery runs a nearest-neighbour search the way retrieval does, using a
// stored embedding as the query, so the restored vectors and operators work.
func vectorQuery(ctx context.Context, pool *pgxpool.Pool) error {
	var n int
	return pool.QueryRow(ctx, `SELECT count(*) FROM (
		SELECT id FROM kb_chunks
		ORDER BY embedding <=> (SELECT embedding FROM kb_chunks LIMIT 1)
		LIMIT 5) nearest`).Scan(&n)
}
