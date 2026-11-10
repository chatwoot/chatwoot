package answereval

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/profile"
)

type memProfiles struct {
	byAcct map[int64]profile.Profile
	saves  int
}

func (m *memProfiles) Get(_ context.Context, acct int64) (profile.Profile, error) {
	if p, ok := m.byAcct[acct]; ok {
		return p, nil
	}
	return profile.Profile{AccountID: acct}, nil
}

func (m *memProfiles) Save(_ context.Context, p profile.Profile) error {
	m.saves++
	m.byAcct[p.AccountID] = p
	return nil
}

func profileFile(t *testing.T, body string) string {
	t.Helper()
	path := filepath.Join(t.TempDir(), "profile.json")
	if err := os.WriteFile(path, []byte(body), 0o600); err != nil {
		t.Fatal(err)
	}
	return path
}

const cafe = `{"business_name": "Sample Coffee", "about": "A café.", "tone": "Friendly.", "contact": "Ask staff in this chat.", "rules": "Never invent prices."}`

func TestSeedProfile_FillsAnEmptyAccountAndUpdatesItsOwn(t *testing.T) {
	// Arrange
	ps := &memProfiles{byAcct: map[int64]profile.Profile{}}
	path := profileFile(t, cafe)

	// Act
	first := SeedProfile(context.Background(), ps, 9001, path)
	ps.byAcct[9001] = profile.Profile{AccountID: 9001, BusinessName: "Sample Coffee", About: "old"}
	again := SeedProfile(context.Background(), ps, 9001, path)

	// Assert
	if first != nil || again != nil {
		t.Fatalf("errors: %v / %v", first, again)
	}
	p := ps.byAcct[9001]
	if p.BusinessName != "Sample Coffee" || p.About != "A café." || p.Contact != "Ask staff in this chat." || p.Rules != "Never invent prices." || ps.saves != 2 {
		t.Errorf("profile = %+v saves=%d", p, ps.saves)
	}
}

func TestSeedProfile_RefusesAnotherBusinessesProfile(t *testing.T) {
	// Arrange
	real := profile.Profile{AccountID: 1, BusinessName: "Johnstocker AI Studio", About: "real"}
	ps := &memProfiles{byAcct: map[int64]profile.Profile{1: real}}

	// Act
	err := SeedProfile(context.Background(), ps, 1, profileFile(t, cafe))

	// Assert
	if err == nil || !strings.Contains(err.Error(), "Johnstocker AI Studio") {
		t.Fatalf("err = %v", err)
	}
	if ps.saves != 0 || ps.byAcct[1].About != "real" {
		t.Error("a refused seed changed the profile")
	}
}

func TestSeedProfile_RejectsAFileWithoutABusinessName(t *testing.T) {
	// Arrange
	ps := &memProfiles{byAcct: map[int64]profile.Profile{}}

	// Act
	noName := SeedProfile(context.Background(), ps, 9001, profileFile(t, `{"about": "x"}`))
	broken := SeedProfile(context.Background(), ps, 9001, profileFile(t, `{`))

	// Assert
	if noName == nil || broken == nil || ps.saves != 0 {
		t.Fatalf("noName=%v broken=%v saves=%d", noName, broken, ps.saves)
	}
}

func TestWithAccount_RunsEveryCaseAsOneAccount(t *testing.T) {
	// Arrange
	cases := []Case{{Name: "a", AccountID: 1}, {Name: "b", AccountID: 2}}

	// Act
	moved := WithAccount(cases, 9001)
	kept := WithAccount(cases, 0)

	// Assert
	if moved[0].AccountID != 9001 || moved[1].AccountID != 9001 {
		t.Errorf("moved = %+v", moved)
	}
	if kept[0].AccountID != 1 || kept[1].AccountID != 2 || cases[0].AccountID != 1 {
		t.Errorf("kept = %+v; the input must not change", kept)
	}
}

func TestSampleProfile_IsValid(t *testing.T) {
	// Arrange
	ps := &memProfiles{byAcct: map[int64]profile.Profile{}}

	// Act
	err := SeedProfile(context.Background(), ps, 9001, "../../testdata/sample-kb/profile.json")

	// Assert
	if err != nil || ps.byAcct[9001].BusinessName != "Sample Coffee" {
		t.Fatalf("err=%v profile=%+v", err, ps.byAcct[9001])
	}
}
