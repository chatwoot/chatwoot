// Package profile holds the business profile of each Chatwoot account: who the
// business is, what it sells, how the bot should sound, how customers buy or
// reach staff, and house rules. One ai-service serves several businesses; the
// profile turns the shared base prompt into that business's assistant.
package profile

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"
	"unicode/utf8"
)

// Field limits, in characters (Thai text is 3 bytes per character).
const (
	MaxNameRunes  = 120
	MaxFieldRunes = 4000
)

// Profile is one account's business profile. Empty fields are left out of the prompt.
type Profile struct {
	AccountID    int64
	BusinessName string
	About        string // industry, products, services
	Tone         string // voice, persona, language preferences
	Contact      string // how to buy, pay, or reach staff
	Rules        string // do and don't
	UpdatedAt    time.Time
}

// Empty reports whether no field is filled.
func (p Profile) Empty() bool {
	return p.BusinessName == "" && p.About == "" && p.Tone == "" && p.Contact == "" && p.Rules == ""
}

// Normalize trims every field and turns CRLF into LF.
func (p Profile) Normalize() Profile {
	clean := func(s string) string {
		return strings.TrimSpace(strings.ReplaceAll(s, "\r\n", "\n"))
	}
	p.BusinessName = clean(p.BusinessName)
	p.About = clean(p.About)
	p.Tone = clean(p.Tone)
	p.Contact = clean(p.Contact)
	p.Rules = clean(p.Rules)
	return p
}

// Validate checks a profile before it is saved.
func (p Profile) Validate() error {
	var errs []error
	if p.AccountID < 1 {
		errs = append(errs, errors.New("account ID must be a positive number"))
	}
	check := func(label, value string, limit int) {
		// Postgres TEXT rejects NUL, so catch it here with a clear message.
		if !utf8.ValidString(value) || strings.ContainsRune(value, 0) {
			errs = append(errs, fmt.Errorf("%s must be valid UTF-8 text", label))
			return
		}
		if n := utf8.RuneCountInString(value); n > limit {
			errs = append(errs, fmt.Errorf("%s is %d characters; the limit is %d", label, n, limit))
		}
	}
	check("business name", p.BusinessName, MaxNameRunes)
	check("about", p.About, MaxFieldRunes)
	check("tone", p.Tone, MaxFieldRunes)
	check("contact", p.Contact, MaxFieldRunes)
	check("rules", p.Rules, MaxFieldRunes)
	return errors.Join(errs...)
}

// Prompt appends the business profile to the shared base prompt. The base
// comes first so its safety rules (never invent prices, hand off when unsure)
// frame everything the business adds.
func Prompt(base string, p Profile) string {
	if p.Empty() {
		return base
	}
	var b strings.Builder
	b.WriteString(base)
	b.WriteString("\n\n# The business you represent\n")
	b.WriteString("Answer only about this business. Business facts come from this profile and the knowledge excerpts; if neither covers a question, say you do not know and offer a staff member.\n")
	section := func(title, body string) {
		if body != "" {
			b.WriteString("\n## " + title + "\n" + body + "\n")
		}
	}
	section("Name", p.BusinessName)
	section("About", p.About)
	section("Tone and style", p.Tone)
	section("How customers buy or reach staff", p.Contact)
	section("Rules", p.Rules)
	return strings.TrimRight(b.String(), "\n")
}

// Store loads and saves profiles.
type Store interface {
	// Get returns the account's profile, or an empty one when none is saved.
	Get(ctx context.Context, accountID int64) (Profile, error)
	Save(ctx context.Context, p Profile) error
}
