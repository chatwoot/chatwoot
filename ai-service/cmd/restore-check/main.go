// Command restore-check verifies a restored ai-service backup in a scratch
// database: it runs Migrate, then checks the vector extension, the schema
// version, every required table, minimum row counts and one vector query.
// It prints a JSON report with table names and counts only (no row content)
// and exits 1 when anything is wrong. Issue: DEV-Johnstocker/chatwoot#1
//
// It reads RESTORE_DATABASE_URL, not DATABASE_URL, so the production setting
// is never picked up by accident, and it refuses any host that is not local.
// deploy/restore-drill.sh runs it against a throwaway container:
//
//	RESTORE_DATABASE_URL=postgres://... restore-check -min-rows kb_documents=1
package main

import (
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"os"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/restorecheck"
	"github.com/jackc/pgx/v5/pgxpool"
)

func main() {
	ok, err := run()
	if err != nil {
		fmt.Fprintln(os.Stderr, "restore-check:", err)
		os.Exit(2)
	}
	if !ok {
		os.Exit(1)
	}
}

func run() (bool, error) {
	minRowsFlag := flag.String("min-rows", "", "minimum rows per table, e.g. kb_documents=1,business_profiles=1")
	wantVersion := flag.Int("want-version", knowledge.SchemaVersion, "schema version expected after Migrate")
	flag.Parse()

	dsn := os.Getenv("RESTORE_DATABASE_URL")
	if dsn == "" {
		return false, errors.New("RESTORE_DATABASE_URL is not set")
	}
	if err := restorecheck.CheckLoopback(dsn); err != nil {
		return false, err
	}
	minRows, err := restorecheck.ParseMinRows(*minRowsFlag)
	if err != nil {
		return false, err
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		return false, errors.New("database config does not parse")
	}
	defer pool.Close()
	if err := pool.Ping(ctx); err != nil {
		return false, fmt.Errorf("database ping: %w", err)
	}

	report, err := restorecheck.Run(ctx, pool)
	if err != nil {
		return false, err
	}
	report.Evaluate(*wantVersion, minRows)
	out := json.NewEncoder(os.Stdout)
	out.SetIndent("", "  ")
	if err := out.Encode(report); err != nil {
		return false, err
	}
	return len(report.Problems) == 0, nil
}
