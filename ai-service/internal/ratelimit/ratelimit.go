// Package ratelimit is a fixed one-minute window counter per key. When it is
// full it evicts only expired windows; if still full it refuses new keys
// (fails closed) instead of forgetting counts, so flooding it with new keys
// cannot reset anyone's limit.
package ratelimit

import (
	"sync"
	"time"
)

// Window is the counting period.
const Window = time.Minute

// Limiter counts calls per key.
type Limiter struct {
	Max int // most keys tracked at once; 0 means 10000

	mu   sync.Mutex
	keys map[string]*entry
	now  func() time.Time
}

type entry struct {
	start time.Time
	n     int
}

// Allow counts one call for key and reports whether it is within limit.
func (l *Limiter) Allow(key string, limit int) bool {
	l.mu.Lock()
	defer l.mu.Unlock()
	now := time.Now()
	if l.now != nil {
		now = l.now()
	}
	if l.keys == nil {
		l.keys = map[string]*entry{}
	}
	e := l.keys[key]
	if e == nil || now.Sub(e.start) >= Window {
		if e == nil && len(l.keys) >= l.max() {
			for k, old := range l.keys {
				if now.Sub(old.start) >= Window {
					delete(l.keys, k)
				}
			}
			if len(l.keys) >= l.max() {
				return false
			}
		}
		e = &entry{start: now}
		l.keys[key] = e
	}
	e.n++
	return e.n <= limit
}

func (l *Limiter) max() int {
	if l.Max > 0 {
		return l.Max
	}
	return 10000
}
