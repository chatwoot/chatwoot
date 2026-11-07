package answereval

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
)

type memKB struct {
	docs []knowledge.Document
}

func (m *memKB) List(_ context.Context, acct int64) ([]knowledge.Document, error) {
	var out []knowledge.Document
	for _, d := range m.docs {
		if d.AccountID == acct {
			out = append(out, d)
		}
	}
	return out, nil
}

func (m *memKB) Upsert(_ context.Context, d knowledge.Document) (knowledge.Document, int64, int, error) {
	for i, old := range m.docs {
		if old.AccountID == d.AccountID && old.SourceKey == d.SourceKey {
			m.docs[i] = d
			return old, int64(i + 1), 1, nil
		}
	}
	m.docs = append(m.docs, d)
	return knowledge.Document{}, int64(len(m.docs)), 1, nil
}

func writeFAQs(t *testing.T, body string) string {
	t.Helper()
	p := filepath.Join(t.TempDir(), "faq.json")
	if err := os.WriteFile(p, []byte(body), 0o600); err != nil {
		t.Fatal(err)
	}
	return p
}

func TestSeed_LoadsFAQsIntoEmptyAccount(t *testing.T) {
	// Arrange
	kb := &memKB{}
	path := writeFAQs(t, `[{"question":"Open when?","answer":"8 to 6"},{"question":"Where?","answer":"Bangkok"}]`)

	// Act
	n, err := Seed(context.Background(), kb, 7, path)
	again, err2 := Seed(context.Background(), kb, 7, path)

	// Assert
	if err != nil || err2 != nil || n != 2 || again != 2 {
		t.Fatalf("n=%d again=%d err=%v err2=%v", n, again, err, err2)
	}
	if len(kb.docs) != 2 {
		t.Fatalf("docs = %d, want 2 (a second seed updates in place)", len(kb.docs))
	}
	d := kb.docs[0]
	if d.AccountID != 7 || d.Kind != knowledge.KindFAQ || d.Title != "Open when?" || d.Content != "8 to 6" || !strings.HasPrefix(d.SourceKey, SeedKeyPrefix) {
		t.Fatalf("doc = %+v", d)
	}
}

func TestSeed_RefusesAccountWithRealKnowledge(t *testing.T) {
	// Arrange: the account already holds a document that seeding did not add.
	kb := &memKB{docs: []knowledge.Document{{AccountID: 1, Title: "Real price list", SourceKey: "product-001"}}}
	path := writeFAQs(t, `[{"question":"Q","answer":"A"}]`)

	// Act
	_, err := Seed(context.Background(), kb, 1, path)

	// Assert
	if err == nil || len(kb.docs) != 1 {
		t.Fatalf("err=%v docs=%d: seeding must refuse and change nothing", err, len(kb.docs))
	}
}

func TestSeed_RejectsBadFile(t *testing.T) {
	// Arrange
	kb := &memKB{}
	cases := map[string]string{
		"not json":     `nope`,
		"empty list":   `[]`,
		"blank answer": `[{"question":"Q","answer":" "}]`,
	}
	for name, body := range cases {
		t.Run(name, func(t *testing.T) {
			// Act
			_, err := Seed(context.Background(), kb, 1, writeFAQs(t, body))

			// Assert
			if err == nil || len(kb.docs) != 0 {
				t.Fatalf("err=%v docs=%d", err, len(kb.docs))
			}
		})
	}
}

func TestReport_Unfaithful(t *testing.T) {
	// Arrange
	yes, no := true, false
	r := Report{Results: []Result{{Faithful: &yes}, {Faithful: &no}, {}, {Faithful: &no}}}

	// Act
	n := r.Unfaithful()

	// Assert
	if n != 2 {
		t.Fatalf("Unfaithful() = %d, want 2", n)
	}
}
