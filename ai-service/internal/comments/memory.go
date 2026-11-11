package comments

import (
	"context"
	"slices"
	"sync"
	"time"
)

// Memory implements Store in memory, with the same rules as Postgres. It is
// for tests.
type Memory struct {
	mu     sync.Mutex
	nextID int64
	rows   []Comment
	// replied holds when a private reply was sent, by row ID. Forget keeps
	// it, like the replied_at column in Postgres.
	replied map[int64]time.Time
}

func (m *Memory) find(id int64) int {
	return slices.IndexFunc(m.rows, func(c Comment) bool { return c.ID == id })
}

// Add implements Store.
func (m *Memory) Add(_ context.Context, c Comment) (bool, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	if slices.ContainsFunc(m.rows, func(r Comment) bool { return r.CommentID == c.CommentID }) {
		return false, nil
	}
	m.nextID++
	c.ID, c.Status, c.Version, c.Received = m.nextID, StatusNew, 1, time.Now()
	m.rows = append(m.rows, c)
	return true, nil
}

// Forget implements Store.
func (m *Memory) Forget(_ context.Context, c Comment) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	i := slices.IndexFunc(m.rows, func(r Comment) bool { return r.CommentID == c.CommentID })
	if i < 0 {
		m.nextID++
		m.rows = append(m.rows, Comment{ID: m.nextID, AccountID: c.AccountID, PageID: c.PageID, CommentID: c.CommentID,
			CreatedAt: time.Now(), Received: time.Now(), Status: StatusRemoved, Version: 1})
		return nil
	}
	r := &m.rows[i]
	r.Message, r.FromName, r.Reason, r.Draft, r.Reply, r.Error = "", "", "", "", "", ""
	r.Status = StatusRemoved
	r.Version++
	return nil
}

// Unscored implements Store.
func (m *Memory) Unscored(_ context.Context, limit int) ([]Comment, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	var out []Comment
	for _, c := range m.rows {
		if c.Status == StatusNew {
			out = append(out, c)
		}
	}
	slices.SortStableFunc(out, func(a, b Comment) int { return a.Attempts - b.Attempts })
	if len(out) > limit {
		out = out[:limit]
	}
	return out, nil
}

// Retry implements Store.
func (m *Memory) Retry(_ context.Context, id int64) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	i := m.find(id)
	if i < 0 || m.rows[i].Status != StatusNew {
		return ErrNotFound
	}
	c := &m.rows[i]
	c.Attempts++
	if c.Attempts >= MaxScoreAttempts {
		c.Status, c.Reason = StatusWaiting, UnscoredReason
		c.Version++
	}
	return nil
}

// Score implements Store.
func (m *Memory) Score(_ context.Context, id int64, intent Intent, reason, draft string) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	i := m.find(id)
	if i < 0 || m.rows[i].Status != StatusNew {
		return ErrNotFound
	}
	c := &m.rows[i]
	c.Intent, c.Reason, c.Draft, c.Status = intent, reason, draft, StatusWaiting
	if intent == IntentOther {
		c.Status = StatusIgnored
	}
	c.Version++
	return nil
}

// Waiting implements Store.
func (m *Memory) Waiting(_ context.Context, accountID int64) ([]Comment, error) {
	return m.list(accountID, MaxWaitingShown, func(s Status) bool { return s == StatusWaiting }), nil
}

// Recent implements Store.
func (m *Memory) Recent(_ context.Context, accountID int64, limit int) ([]Comment, error) {
	return m.list(accountID, limit, func(s Status) bool {
		return s != StatusNew && s != StatusWaiting && s != StatusRemoved
	}), nil
}

func (m *Memory) list(accountID int64, limit int, keep func(Status) bool) []Comment {
	m.mu.Lock()
	defer m.mu.Unlock()
	var out []Comment
	for i := len(m.rows) - 1; i >= 0; i-- {
		c := m.rows[i]
		if c.AccountID == accountID && keep(c.Status) && (limit < 0 || len(out) < limit) {
			out = append(out, c)
		}
	}
	return out
}

// Get implements Store.
func (m *Memory) Get(_ context.Context, accountID, id int64) (Comment, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	i := m.find(id)
	if i < 0 || m.rows[i].AccountID != accountID {
		return Comment{}, ErrNotFound
	}
	return m.rows[i], nil
}

// Claim implements Store.
func (m *Memory) Claim(_ context.Context, accountID, id int64, version int) (Comment, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	i := m.find(id)
	if i < 0 || m.rows[i].AccountID != accountID {
		return Comment{}, ErrNotFound
	}
	c := &m.rows[i]
	if c.Status != StatusWaiting || c.Version != version {
		return Comment{}, ErrChanged
	}
	c.Status = StatusSending
	c.Version++
	return *c, nil
}

// Finish implements Store.
func (m *Memory) Finish(_ context.Context, id int64, status Status, reply, by, errText string) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	i := m.find(id)
	if i < 0 || m.rows[i].Status != StatusSending {
		return ErrNotFound
	}
	c := &m.rows[i]
	c.Status, c.Error = status, errText
	if status != StatusWaiting {
		c.Reply, c.DecidedBy, c.DecidedAt = reply, by, time.Now()
	}
	if status == StatusSent {
		if m.replied == nil {
			m.replied = map[int64]time.Time{}
		}
		m.replied[c.ID] = c.DecidedAt
	}
	c.Version++
	return nil
}

// Dismiss implements Store.
func (m *Memory) Dismiss(_ context.Context, accountID, id int64, version int, by string) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	i := m.find(id)
	if i < 0 || m.rows[i].AccountID != accountID {
		return ErrNotFound
	}
	c := &m.rows[i]
	if c.Status != StatusWaiting || c.Version != version {
		return ErrChanged
	}
	c.Status, c.DecidedBy, c.DecidedAt = StatusDismissed, by, time.Now()
	c.Version++
	return nil
}

// Purge implements Store.
func (m *Memory) Purge(_ context.Context, cutoff time.Time) (int64, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	before := len(m.rows)
	m.rows = slices.DeleteFunc(m.rows, func(c Comment) bool {
		if c.Received.Before(cutoff) {
			delete(m.replied, c.ID)
			return true
		}
		return false
	})
	return int64(before - len(m.rows)), nil
}

// SaveReview implements Store.
func (m *Memory) SaveReview(_ context.Context, id int64, r Review) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	i := m.find(id)
	if i < 0 {
		return ErrNotFound
	}
	m.rows[i].Review = &r
	return nil
}

// ReviewStats implements Store.
func (m *Memory) ReviewStats(_ context.Context, accountID int64) (ReviewStats, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	var s ReviewStats
	for _, c := range m.rows {
		if c.AccountID == accountID {
			s.add(c)
		}
	}
	return s, nil
}

// LastReplies implements Store.
func (m *Memory) LastReplies(_ context.Context, accountID int64, fromIDs []string) (map[string]time.Time, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	want := map[string]bool{}
	for _, id := range fromIDs {
		want[id] = true
	}
	out := map[string]time.Time{}
	for _, c := range m.rows {
		at, ok := m.replied[c.ID]
		if ok && c.AccountID == accountID && want[c.FromID] && at.After(out[c.FromID]) {
			out[c.FromID] = at
		}
	}
	return out, nil
}
