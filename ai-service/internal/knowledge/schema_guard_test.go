package knowledge

// Static guard for the embedded schema files (AGENTS.md §5). It runs without a
// database, so every PR checks it. Idea adapted from the migration-safety
// script in the owner's private project-reuse-toolkit; this is a fresh Go
// implementation, not copied code. Issue: DEV-Johnstocker/chatwoot#1
//
// It is a guard rail, not a SQL parser: the pgvector integration tests and
// the migration reviewer remain the real checks.

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"os"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"testing"
)

// appliedSchemaSHA256 freezes every schema file that has reached production.
// An applied change must never be edited (§5): fix forward in a new version.
// When you add schema_vN.sql, add its hash here in the same PR.
var appliedSchemaSHA256 = map[string]string{
	"schema.sql":     "a09ec2ac7d870db5996bd302c6f53d21ecbd7b42e732f6a156f51be8bdadf9d9",
	"schema_v2.sql":  "dc4ab2d5087c765a0219834fd0f1aaa756f236e0b1c52c16e0e5d88ee9e8bac3",
	"schema_v3.sql":  "5fc62d93cc2068219e302e09350340c66f4d2b111e6a858f656a64f4ced8acd7",
	"schema_v4.sql":  "1481b965f60608d6e9545398cea3501cd7359c5fca1e25ae5847d5e384a9c081",
	"schema_v5.sql":  "c459df5ff23e6966b6653d6bc7410cdde57488d82625bc6c7252428b963f1461",
	"schema_v6.sql":  "427eaa48bfc47321521312123110232899b6e5b39cec619f057e698644cb6b92",
	"schema_v7.sql":  "09eaa3283ec36aa563d612e3ca069b983c3a6c70f42a553214d920322552dc2b",
	"schema_v8.sql":  "15640bd9ac51fe131c98d9b4a2aa3c5d88fc0f445313b22b7b8e7e79cdff1ece",
	"schema_v9.sql":  "f609d860cc9b86ba3ebde332c0171924f9442c0747c263a73b7bc29bf49e6814",
	"schema_v10.sql": "432c5600faf4c5cc64da6c42665e85f38c8fc642d49ee0f0588fa413dc9363d7",
	"schema_v11.sql": "932b9b38c76b70c2994d70a2489da91a7b8ff9298d69e0122e263649427b785f",
	"schema_v12.sql": "47903a6b31730a6c96c34d9e17fd2019b64f2360cc90b00bb15933841725896d",
}

// destructiveAck marks a reviewed destructive statement. It must give a reason.
const destructiveAck = "-- destructive-ok:"

var (
	schemaFileName = regexp.MustCompile(`^schema(?:_v(\d+))?\.sql$`)
	lockTimeout    = regexp.MustCompile(`(?i)\bSET\s+LOCAL\s+lock_timeout\b`)
	concurrently   = regexp.MustCompile(`(?i)\b(CREATE|DROP)\s+INDEX\s+CONCURRENTLY\b`)
	destructive    = regexp.MustCompile(`(?i)\bDROP\s+(TABLE|COLUMN|INDEX|SCHEMA|EXTENSION|TYPE|FUNCTION|VIEW)\b` +
		`|\bRENAME\b|\bTRUNCATE\b|\bDELETE\s+FROM\b|\bALTER\s+COLUMN\s+\S+\s+(SET\s+DATA\s+)?TYPE\b`)
	lineComment = regexp.MustCompile(`--[^\n]*`)
)

// checkMigration returns the rule violations of one schema change (v2+).
func checkMigration(sql string) []string {
	var problems []string
	code := lineComment.ReplaceAllString(sql, "")
	if !lockTimeout.MatchString(code) {
		problems = append(problems, "missing SET LOCAL lock_timeout")
	}
	if concurrently.MatchString(code) {
		problems = append(problems, "CONCURRENTLY cannot run inside Migrate's transaction")
	}
	if m := destructive.FindString(code); m != "" && !hasDestructiveAck(sql) {
		problems = append(problems, fmt.Sprintf("destructive statement %q without %q <reason>", m, destructiveAck))
	}
	return problems
}

func hasDestructiveAck(sql string) bool {
	for _, line := range strings.Split(sql, "\n") {
		if reason, ok := strings.CutPrefix(strings.TrimSpace(line), destructiveAck); ok && strings.TrimSpace(reason) != "" {
			return true
		}
	}
	return false
}

// schemaFiles returns version -> file name for every schema file on disk.
func schemaFiles(t *testing.T) map[int]string {
	t.Helper()
	entries, err := os.ReadDir(".")
	if err != nil {
		t.Fatal(err)
	}
	files := map[int]string{}
	for _, e := range entries {
		m := schemaFileName.FindStringSubmatch(e.Name())
		if m == nil {
			continue
		}
		version := 1
		if m[1] != "" {
			version, _ = strconv.Atoi(m[1])
		}
		files[version] = e.Name()
	}
	return files
}

func TestSchemaFiles_AreContiguousAndApplied(t *testing.T) {
	// Arrange
	files := schemaFiles(t)
	src, err := os.ReadFile("postgres.go")
	if err != nil {
		t.Fatal(err)
	}
	migrate := string(src)

	// Act
	versions := make([]int, 0, len(files))
	for v := range files {
		versions = append(versions, v)
	}
	sort.Ints(versions)

	// Assert
	if latest := versions[len(versions)-1]; latest != SchemaVersion {
		t.Errorf("SchemaVersion is %d but the newest schema file is version %d", SchemaVersion, latest)
	}
	for i, v := range versions {
		if v != i+1 {
			t.Fatalf("schema versions must be 1..N with no gap; got %v", versions)
		}
		name := files[v]
		if !strings.Contains(migrate, "//go:embed "+name+"\n") {
			t.Errorf("%s is not embedded in postgres.go", name)
		}
		if !strings.Contains(migrate, fmt.Sprintf("SET version = %d\"", v)) {
			t.Errorf("Migrate never records version %d (%s)", v, name)
		}
	}
}

func TestSchemaFiles_AppliedFilesAreUnchanged(t *testing.T) {
	for _, name := range schemaFiles(t) {
		// Arrange
		want, ok := appliedSchemaSHA256[name]
		if !ok {
			t.Errorf("%s has no frozen hash: add it to appliedSchemaSHA256", name)
			continue
		}

		// Act
		data, err := os.ReadFile(name)
		if err != nil {
			t.Fatal(err)
		}
		sum := sha256.Sum256(data)

		// Assert
		if got := hex.EncodeToString(sum[:]); got != want {
			t.Errorf("%s changed (sha256 %s); applied schema is frozen, add a new version instead", name, got)
		}
	}
}

func TestSchemaFiles_FollowMigrationRules(t *testing.T) {
	for v, name := range schemaFiles(t) {
		if v == 1 {
			continue // the initial CREATE-only schema predates the lock_timeout rule
		}
		// Arrange
		data, err := os.ReadFile(name)
		if err != nil {
			t.Fatal(err)
		}

		// Act
		problems := checkMigration(string(data))

		// Assert
		for _, p := range problems {
			t.Errorf("%s: %s", name, p)
		}
	}
}

func TestCheckMigration(t *testing.T) {
	const lock = "SET LOCAL lock_timeout = '5s';\n"
	cases := []struct {
		name string
		sql  string
		want string // substring of the single expected problem; "" = clean
	}{
		{"additive change is clean", lock + "ALTER TABLE t ADD COLUMN c TEXT;", ""},
		{"constraint swap is allowed", lock + "ALTER TABLE t DROP CONSTRAINT IF EXISTS t_c_check;", ""},
		{"missing lock timeout", "ALTER TABLE t ADD COLUMN c TEXT;", "lock_timeout"},
		{"lock timeout only in a comment", "-- SET LOCAL lock_timeout = '5s';\nALTER TABLE t ADD COLUMN c TEXT;", "lock_timeout"},
		{"drop column", lock + "ALTER TABLE t DROP COLUMN c;", "DROP COLUMN"},
		{"drop table", lock + "DROP TABLE IF EXISTS t;", "DROP TABLE"},
		{"rename", lock + "ALTER TABLE t RENAME COLUMN a TO b;", "RENAME"},
		{"type change", lock + "ALTER TABLE t ALTER COLUMN c TYPE BIGINT;", "ALTER COLUMN"},
		{"delete rows", lock + "DELETE FROM t;", "DELETE FROM"},
		{"truncate", lock + "TRUNCATE t;", "TRUNCATE"},
		{"concurrent index", lock + "CREATE INDEX CONCURRENTLY i ON t (c);", "CONCURRENTLY"},
		{"empty acknowledgement does not count", lock + destructiveAck + "\nDROP TABLE t;", "DROP TABLE"},
		{"acknowledged destructive change", lock + destructiveAck + " table unused since v9, readers removed in #50\nDROP TABLE t;", ""},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			// Arrange: tc.sql

			// Act
			problems := checkMigration(tc.sql)

			// Assert
			if tc.want == "" {
				if len(problems) != 0 {
					t.Fatalf("want clean, got %v", problems)
				}
				return
			}
			if len(problems) != 1 || !strings.Contains(problems[0], tc.want) {
				t.Fatalf("want one problem containing %q, got %v", tc.want, problems)
			}
		})
	}
}
