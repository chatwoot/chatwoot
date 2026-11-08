package pending

import (
	"context"
	"encoding/json"
	"fmt"
	"slices"
	"sync"
	"time"
)

// Memory implements Store in memory, with the same rules as Postgres. It is
// for tests of the packages that use a Store.
type Memory struct {
	mu      sync.Mutex
	nextID  int64
	changes []Change
}

// Propose implements Store.
func (m *Memory) Propose(_ context.Context, c Change) (int64, error) {
	if c.Kind != KindProfile && c.Kind != KindDocument {
		return 0, fmt.Errorf("unknown change kind %q", c.Kind)
	}
	m.mu.Lock()
	defer m.mu.Unlock()
	waiting := 0
	for i, cur := range m.changes {
		if cur.AccountID != c.AccountID {
			continue
		}
		waiting++
		if cur.Kind == c.Kind && cur.Target == c.Target {
			proposed := c.Proposed
			if c.Kind == KindProfile {
				merged, err := mergeJSON(cur.Proposed, c.Proposed)
				if err != nil {
					return 0, err
				}
				proposed = merged
			}
			m.changes[i].Proposed, m.changes[i].Actor, m.changes[i].TokenID = proposed, c.Actor, c.TokenID
			m.changes[i].Version++
			m.changes[i].At = time.Now()
			return cur.ID, nil
		}
	}
	if waiting >= MaxPerAccount {
		return 0, ErrFull
	}
	m.nextID++
	c.ID, c.Version, c.At = m.nextID, 1, time.Now()
	m.changes = append(m.changes, c)
	return c.ID, nil
}

func mergeJSON(old, newer json.RawMessage) (json.RawMessage, error) {
	var a, b map[string]json.RawMessage
	if err := json.Unmarshal(old, &a); err != nil {
		return nil, err
	}
	if err := json.Unmarshal(newer, &b); err != nil {
		return nil, err
	}
	for k, v := range b {
		a[k] = v
	}
	return json.Marshal(a)
}

// List implements Store.
func (m *Memory) List(_ context.Context, accountID int64) ([]Change, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	var out []Change
	for _, c := range m.changes {
		if c.AccountID == accountID {
			out = append(out, c)
		}
	}
	return out, nil
}

// Get implements Store.
func (m *Memory) Get(_ context.Context, accountID, id int64) (Change, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	for _, c := range m.changes {
		if c.AccountID == accountID && c.ID == id {
			return c, nil
		}
	}
	return Change{}, ErrNotFound
}

// Remove implements Store.
func (m *Memory) Remove(_ context.Context, accountID, id int64, version int) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	i := slices.IndexFunc(m.changes, func(c Change) bool { return c.AccountID == accountID && c.ID == id })
	switch {
	case i < 0:
		return ErrNotFound
	case m.changes[i].Version != version:
		return ErrChanged
	}
	m.changes = slices.Delete(m.changes, i, i+1)
	return nil
}

// Count implements Store.
func (m *Memory) Count(ctx context.Context, accountID int64) (int, error) {
	l, err := m.List(ctx, accountID)
	return len(l), err
}
