// Package ratelimit is a fixed one-minute window counter per key. When it is
// full it evicts only expired windows; if still full it refuses new keys
// (fails closed) instead of forgetting counts, so flooding it with new keys
// cannot reset anyone's limit.
package ratelimit

import (
	"net"
	"net/http"
	"strings"
	"sync"
	"time"
)

// ClientIP is the caller's address for rate limits and logs. Behind the
// Cloudflare tunnel every request arrives from the tunnel container on a
// private network, so the visitor's address is taken from CF-Connecting-IP,
// but only then: a direct caller cannot pick its own key.
func ClientIP(r *http.Request) string {
	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		host = r.RemoteAddr
	}
	if ip := net.ParseIP(host); ip != nil && (ip.IsPrivate() || ip.IsLoopback()) {
		if cf := strings.TrimSpace(r.Header.Get("CF-Connecting-IP")); net.ParseIP(cf) != nil {
			return cf
		}
	}
	return host
}

// Window is the counting period.
const Window = time.Minute

// Limiter counts calls per key.
type Limiter struct {
	Max    int           // most keys tracked at once; 0 means 10000
	Period time.Duration // counting window; 0 means Window (one minute)

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
	period := l.period()
	if e == nil || now.Sub(e.start) >= period {
		if e == nil && len(l.keys) >= l.max() {
			for k, old := range l.keys {
				if now.Sub(old.start) >= period {
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

// Reached reports whether key has already used limit calls in the current
// window, without counting a call.
func (l *Limiter) Reached(key string, limit int) bool {
	l.mu.Lock()
	defer l.mu.Unlock()
	now := time.Now()
	if l.now != nil {
		now = l.now()
	}
	e := l.keys[key]
	return e != nil && now.Sub(e.start) < l.period() && e.n >= limit
}

func (l *Limiter) period() time.Duration {
	if l.Period > 0 {
		return l.Period
	}
	return Window
}

func (l *Limiter) max() int {
	if l.Max > 0 {
		return l.Max
	}
	return 10000
}
