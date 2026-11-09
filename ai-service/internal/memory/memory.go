// Package memory holds short-lived in-process state: per-conversation chat
// history and a seen-message set for idempotency.
//
// Chatwoot does not let Agent Bot tokens list messages
// (BOT_ACCESSIBLE_ENDPOINTS allows only messages#create), so history is built
// from webhook events. State is lost on restart; that is acceptable for the
// MVP and is replaced by a persistent store in a later phase.
package memory

import (
	"sync"
	"time"
)

// Turn is one remembered message. Role is "user" or "assistant".
// PageMessagePrefix marks an assistant turn the Facebook Page sent itself
// (Instant Reply, an ad's welcome message, an Away message): it came back as a
// Messenger echo, not from the bot. The model still sees it as context, but it
// does not count as the bot having spoken.
const PageMessagePrefix = "[Page message] "

type Turn struct {
	Role    string
	Content string
}

type convKey struct{ account, conversation int64 }

type thread struct {
	turns    []Turn
	lastSeen time.Time
}

// History keeps the last `limit` turns per conversation and forgets
// conversations idle for longer than `ttl`.
type History struct {
	mu      sync.Mutex
	limit   int
	ttl     time.Duration
	now     func() time.Time
	threads map[convKey]*thread
}

// NewHistory returns a History. now may be nil (time.Now).
func NewHistory(limit int, ttl time.Duration, now func() time.Time) *History {
	if now == nil {
		now = time.Now
	}
	return &History{limit: limit, ttl: ttl, now: now, threads: map[convKey]*thread{}}
}

// Append adds a turn, trimming the oldest beyond the limit.
func (h *History) Append(account, conversation int64, t Turn) {
	h.mu.Lock()
	defer h.mu.Unlock()
	now := h.now()
	h.evictIdle(now)
	k := convKey{account, conversation}
	th := h.threads[k]
	if th == nil {
		th = &thread{}
		h.threads[k] = th
	}
	th.turns = append(th.turns, t)
	if over := len(th.turns) - h.limit; over > 0 {
		th.turns = append([]Turn(nil), th.turns[over:]...)
	}
	th.lastSeen = now
}

// Get returns a copy of the conversation's turns, oldest first.
func (h *History) Get(account, conversation int64) []Turn {
	h.mu.Lock()
	defer h.mu.Unlock()
	th := h.threads[convKey{account, conversation}]
	if th == nil {
		return nil
	}
	return append([]Turn(nil), th.turns...)
}

// Forget drops a conversation (e.g. when it is resolved).
func (h *History) Forget(account, conversation int64) {
	h.mu.Lock()
	defer h.mu.Unlock()
	delete(h.threads, convKey{account, conversation})
}

// Len reports how many conversations are held (for tests/metrics).
func (h *History) Len() int {
	h.mu.Lock()
	defer h.mu.Unlock()
	return len(h.threads)
}

func (h *History) evictIdle(now time.Time) {
	for k, th := range h.threads {
		if now.Sub(th.lastSeen) > h.ttl {
			delete(h.threads, k)
		}
	}
}

// Seen is a TTL set used to drop duplicate webhook deliveries
// (Chatwoot retries on 429/500 with the same message id).
type Seen struct {
	mu   sync.Mutex
	ttl  time.Duration
	now  func() time.Time
	keys map[string]time.Time
}

// NewSeen returns a Seen set. now may be nil (time.Now).
func NewSeen(ttl time.Duration, now func() time.Time) *Seen {
	if now == nil {
		now = time.Now
	}
	return &Seen{ttl: ttl, now: now, keys: map[string]time.Time{}}
}

// FirstTime records key and reports whether it was not seen within ttl.
func (s *Seen) FirstTime(key string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	now := s.now()
	for k, at := range s.keys {
		if now.Sub(at) > s.ttl {
			delete(s.keys, k)
		}
	}
	if _, dup := s.keys[key]; dup {
		return false
	}
	s.keys[key] = now
	return true
}

// Release removes key so a later retry can be processed (used when the
// event could not be queued).
func (s *Seen) Release(key string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	delete(s.keys, key)
}
