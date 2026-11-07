// Package places remembers the Chatwoot accounts and inboxes the bot has seen,
// with their names, so the admin pages can offer them in a list instead of
// asking the owner to type numeric IDs. Names come from signed webhooks only.
package places

import (
	"context"
	"strings"
	"sync"
	"time"
	"unicode"
)

// Place is one account or inbox.
type Place struct {
	ID   int64
	Name string
}

// Store keeps the names (schema v10).
type Store interface {
	// Record saves the names an incoming webhook carried.
	Record(ctx context.Context, accountID int64, accountName string, inboxID int64, inboxName string) error
	// Accounts lists every known account, by ID.
	Accounts(ctx context.Context) ([]Place, error)
	// Inboxes lists the known inboxes of one account, by ID.
	Inboxes(ctx context.Context, accountID int64) ([]Place, error)
}

// MaxName caps a stored name (the column allows 255 characters).
const MaxName = 255

// CleanName trims a name, drops control characters and caps its length.
func CleanName(s string) string {
	s = strings.Map(func(r rune) rune {
		if unicode.IsControl(r) {
			return ' '
		}
		return r
	}, s)
	s = strings.Join(strings.Fields(s), " ")
	if r := []rune(s); len(r) > MaxName {
		s = strings.TrimSpace(string(r[:MaxName]))
	}
	return s
}

// Recorder writes to Store only when a name changed or an hour has passed,
// so a busy inbox does not cost a database write per message.
type Recorder struct {
	Store Store
	Every time.Duration // minimum gap between unchanged writes; zero is one hour
	Now   func() time.Time

	mu   sync.Mutex
	last map[[2]int64]seen
}

type seen struct {
	account, inbox string
	at             time.Time
}

// maxRemembered bounds the in-memory cache; it is cleared when full.
const maxRemembered = 1000

// Record implements the webhook hook. IDs below 1 are ignored.
func (r *Recorder) Record(ctx context.Context, accountID int64, accountName string, inboxID int64, inboxName string) error {
	if accountID < 1 || inboxID < 1 {
		return nil
	}
	accountName, inboxName = CleanName(accountName), CleanName(inboxName)
	now := time.Now
	if r.Now != nil {
		now = r.Now
	}
	every := r.Every
	if every <= 0 {
		every = time.Hour
	}
	key := [2]int64{accountID, inboxID}
	t := now()

	r.mu.Lock()
	prev, ok := r.last[key]
	if ok && prev.account == accountName && prev.inbox == inboxName && t.Sub(prev.at) < every {
		r.mu.Unlock()
		return nil
	}
	r.mu.Unlock()

	if err := r.Store.Record(ctx, accountID, accountName, inboxID, inboxName); err != nil {
		return err
	}

	r.mu.Lock()
	if r.last == nil || len(r.last) >= maxRemembered {
		r.last = make(map[[2]int64]seen)
	}
	r.last[key] = seen{account: accountName, inbox: inboxName, at: t}
	r.mu.Unlock()
	return nil
}
