package restorecheck

import (
	"strings"
	"testing"
)

func TestCheckLoopback_AllowsOnlyLocalDatabases(t *testing.T) {
	cases := []struct {
		dsn     string
		allowed bool
	}{
		{"postgres://u:p@127.0.0.1:5432/postgres", true},
		{"postgres://u:p@localhost:55001/postgres?sslmode=disable", true},
		{"postgres://u:p@[::1]:5432/postgres", true},
		{"host=/var/run/postgresql dbname=postgres", true},
		// Production and anything remote must be refused: Migrate writes.
		{"postgres://u:p@aws-0-ap-southeast-1.pooler.supabase.com:5432/postgres", false},
		{"postgres://u:p@db.yloatqxcfgpwcqyhgxxp.supabase.co:5432/postgres", false},
		{"postgres://u:p@10.0.0.5:5432/postgres", false},
		{"postgres://u:p@127.0.0.1.example.com:5432/postgres", false},
		{"postgres://u:p@127.0.0.1:5432,db.example.com:5432/postgres", false},
		{"host=127.0.0.1,db.example.com dbname=postgres", false},
		{"not a dsn ::::", false},
		{"", false},
	}
	for _, tc := range cases {
		// Act
		err := CheckLoopback(tc.dsn)

		// Assert
		if tc.allowed && err != nil {
			t.Errorf("%q: want allowed, got %v", tc.dsn, err)
		}
		if !tc.allowed && err == nil {
			t.Errorf("%q: want refused, got allowed", tc.dsn)
		}
		if err != nil && strings.Contains(err.Error(), ":p@") {
			t.Errorf("%q: error leaks the password: %v", tc.dsn, err)
		}
	}
}

func TestParseMinRows(t *testing.T) {
	// Arrange
	input := "kb_documents=1, business_profiles=2"

	// Act
	got, err := ParseMinRows(input)

	// Assert
	if err != nil {
		t.Fatal(err)
	}
	if got["kb_documents"] != 1 || got["business_profiles"] != 2 || len(got) != 2 {
		t.Fatalf("got %v", got)
	}
}

func TestParseMinRows_RejectsBadInput(t *testing.T) {
	for _, input := range []string{"kb_documents", "kb_documents=x", "kb_documents=-1", "=1", "bad name=1", "unknown_table=1"} {
		if _, err := ParseMinRows(input); err == nil {
			t.Errorf("%q: want error", input)
		}
	}
	if got, err := ParseMinRows(""); err != nil || len(got) != 0 {
		t.Errorf("empty: got %v, %v", got, err)
	}
}

func healthyReport() *Report {
	tables := map[string]int64{}
	for _, name := range RequiredTables {
		tables[name] = 3
	}
	return &Report{SchemaBefore: 10, SchemaAfter: 11, VectorSchema: "extensions", Tables: tables, VectorQueryOK: true}
}

func TestEvaluate_HealthyRestorePasses(t *testing.T) {
	// Arrange
	r := healthyReport()

	// Act
	r.Evaluate(11, map[string]int64{"kb_documents": 1})

	// Assert
	if len(r.Problems) != 0 {
		t.Fatalf("want no problems, got %v", r.Problems)
	}
}

func TestEvaluate_ReportsEachFailure(t *testing.T) {
	cases := []struct {
		name   string
		mutate func(*Report)
		mins   map[string]int64
		want   string
	}{
		{"missing table", func(r *Report) { delete(r.Tables, "team_members") }, nil, "missing table team_members"},
		{"too few rows", func(r *Report) { r.Tables["kb_documents"] = 0 }, map[string]int64{"kb_documents": 1}, "kb_documents has 0 rows, want at least 1"},
		{"old schema", func(r *Report) { r.SchemaAfter = 10 }, nil, "schema version 10 after Migrate, want 11"},
		{"no vector", func(r *Report) { r.VectorSchema = "" }, nil, "vector extension missing"},
		{"vector query failed", func(r *Report) { r.VectorQueryOK = false }, nil, "vector query failed"},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			// Arrange
			r := healthyReport()
			tc.mutate(r)

			// Act
			r.Evaluate(11, tc.mins)

			// Assert
			if len(r.Problems) != 1 || !strings.Contains(r.Problems[0], tc.want) {
				t.Fatalf("want one problem containing %q, got %v", tc.want, r.Problems)
			}
		})
	}
}

func TestEvaluate_EmptyChunksSkipVectorQuery(t *testing.T) {
	// Arrange: a backup with no knowledge base yet cannot run a vector query
	r := healthyReport()
	r.Tables["kb_chunks"] = 0
	r.VectorQueryOK = false

	// Act
	r.Evaluate(11, nil)

	// Assert
	if len(r.Problems) != 0 {
		t.Fatalf("want no problems, got %v", r.Problems)
	}
}
