package answereval

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"strings"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/profile"
)

// ProfileStore is the part of profile.Postgres that SeedProfile needs.
type ProfileStore interface {
	Get(ctx context.Context, accountID int64) (profile.Profile, error)
	Save(ctx context.Context, p profile.Profile) error
}

type seedProfile struct {
	BusinessName string `json:"business_name"`
	About        string `json:"about"`
	Tone         string `json:"tone"`
	Contact      string `json:"contact"`
	Rules        string `json:"rules"`
}

// SeedProfile loads a test business profile from a JSON file into a test
// account, for the smoke check. It refuses an account whose profile names a
// different business, so it can never overwrite a real or hand-made profile;
// a profile with the same business name (an earlier seed) is updated.
func SeedProfile(ctx context.Context, ps ProfileStore, accountID int64, path string) error {
	raw, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	var s seedProfile
	if err := json.Unmarshal(raw, &s); err != nil {
		return fmt.Errorf("parse %s: %w", path, err)
	}
	if strings.TrimSpace(s.BusinessName) == "" {
		return errors.New(path + ": business_name is required")
	}
	cur, err := ps.Get(ctx, accountID)
	if err != nil {
		return err
	}
	if cur.BusinessName != "" && cur.BusinessName != s.BusinessName {
		return fmt.Errorf("account %d already has the profile of %q; seed a test account instead", accountID, cur.BusinessName)
	}
	cur.AccountID = accountID
	cur.BusinessName, cur.About, cur.Tone, cur.Contact, cur.Rules = s.BusinessName, s.About, s.Tone, s.Contact, s.Rules
	return ps.Save(ctx, cur)
}

// WithAccount returns a copy of the cases that all run as one account (the
// smoke check's own test account); 0 keeps each case's account.
func WithAccount(cases []Case, accountID int64) []Case {
	out := append([]Case(nil), cases...)
	if accountID > 0 {
		for i := range out {
			out[i].AccountID = accountID
		}
	}
	return out
}
