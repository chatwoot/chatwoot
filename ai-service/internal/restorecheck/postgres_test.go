package restorecheck

import (
	"context"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"testing"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
	"github.com/jackc/pgx/v5/pgxpool"
)

func TestRequiredTables_MatchTheSchemaFiles(t *testing.T) {
	// Arrange
	files, err := filepath.Glob("../knowledge/schema*.sql")
	if err != nil || len(files) == 0 {
		t.Fatalf("no schema files: %v", err)
	}
	create := regexp.MustCompile(`(?i)CREATE TABLE (?:IF NOT EXISTS )?([a-z_]+)`)
	want := map[string]bool{"kb_schema_version": true} // created by Migrate itself

	// Act
	for _, f := range files {
		data, err := os.ReadFile(f)
		if err != nil {
			t.Fatal(err)
		}
		for _, m := range create.FindAllStringSubmatch(string(data), -1) {
			want[strings.ToLower(m[1])] = true
		}
	}

	// Assert
	var wantList []string
	for name := range want {
		wantList = append(wantList, name)
	}
	sort.Strings(wantList)
	got := append([]string(nil), RequiredTables...)
	sort.Strings(got)
	if strings.Join(got, ",") != strings.Join(wantList, ",") {
		t.Fatalf("RequiredTables = %v\nschema files create %v", got, wantList)
	}
}

// Integration test: needs TEST_DATABASE_URL (a scratch database with pgvector),
// like the knowledge package tests. It only reads and migrates; it never drops.
func TestRun_OnScratchDatabase(t *testing.T) {
	dsn := os.Getenv("TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("TEST_DATABASE_URL not set")
	}
	if err := CheckLoopback(dsn); err != nil {
		t.Skipf("TEST_DATABASE_URL is not local: %v", err)
	}
	// Arrange
	ctx := context.Background()
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)

	// Act
	report, err := Run(ctx, pool)
	if err != nil {
		t.Fatal(err)
	}
	report.Evaluate(knowledge.SchemaVersion, nil)

	// Assert
	if len(report.Problems) != 0 {
		t.Fatalf("problems on a migrated scratch database: %v", report.Problems)
	}
	if report.SchemaAfter != knowledge.SchemaVersion || report.VectorSchema == "" {
		t.Fatalf("report = %+v", report)
	}

	// A minimum no restore can meet must be reported, naming the table.
	report.Evaluate(knowledge.SchemaVersion, map[string]int64{"team_members": 1 << 40})
	if len(report.Problems) != 1 || !strings.Contains(report.Problems[0], "team_members") {
		t.Fatalf("want one team_members problem, got %v", report.Problems)
	}
}
