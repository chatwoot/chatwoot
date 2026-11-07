package ratelimit

import (
	"net/http/httptest"
	"testing"
	"time"
)

func TestAllow_CountsPerKeyAndResets(t *testing.T) {
	// Arrange
	now := time.Unix(0, 0)
	l := &Limiter{now: func() time.Time { return now }}

	// Act
	a, b, c := l.Allow("k", 2), l.Allow("k", 2), l.Allow("k", 2)
	other := l.Allow("x", 2)
	now = now.Add(Window)
	later := l.Allow("k", 2)

	// Assert
	if !a || !b || c || !other || !later {
		t.Fatalf("a=%v b=%v c=%v other=%v later=%v", a, b, c, other, later)
	}
}

func TestAllow_FloodOfNewKeysCannotResetALimit(t *testing.T) {
	// Arrange: "login" is at its limit.
	now := time.Unix(0, 0)
	l := &Limiter{Max: 3, now: func() time.Time { return now }}
	for i := 0; i < 5; i++ {
		l.Allow("login", 5)
	}

	// Act: an attacker fills the table with new keys.
	l.Allow("a", 100)
	l.Allow("b", 100)
	flooded := l.Allow("c", 100)
	stillBlocked := l.Allow("login", 5)

	// Assert
	if flooded || stillBlocked {
		t.Fatalf("flooded=%v login allowed again=%v", flooded, stillBlocked)
	}
}

func TestAllow_FullTableEvictsExpiredOnly(t *testing.T) {
	// Arrange
	now := time.Unix(0, 0)
	l := &Limiter{Max: 2, now: func() time.Time { return now }}
	l.Allow("old", 1)
	now = now.Add(Window)
	l.Allow("fresh", 1)

	// Act
	newKey := l.Allow("new", 1)

	// Assert
	if !newKey || len(l.keys) != 2 || l.keys["fresh"] == nil {
		t.Fatalf("newKey=%v keys=%v", newKey, l.keys)
	}
}

func TestClientIP_TrustsCloudflareHeaderOnlyFromPrivateNetwork(t *testing.T) {
	cases := []struct{ remote, cf, want string }{
		{"172.18.0.5:4000", "203.0.113.9", "203.0.113.9"}, // via the tunnel container
		{"127.0.0.1:4000", "203.0.113.9", "203.0.113.9"},
		{"198.51.100.7:4000", "203.0.113.9", "198.51.100.7"}, // direct caller: header ignored
		{"172.18.0.5:4000", "not-an-ip", "172.18.0.5"},
		{"172.18.0.5:4000", "", "172.18.0.5"},
	}
	for _, c := range cases {
		// Arrange
		r := httptest.NewRequest("GET", "/", nil)
		r.RemoteAddr = c.remote
		if c.cf != "" {
			r.Header.Set("CF-Connecting-IP", c.cf)
		}

		// Act
		got := ClientIP(r)

		// Assert
		if got != c.want {
			t.Errorf("remote=%s cf=%q: got %s, want %s", c.remote, c.cf, got, c.want)
		}
	}
}

func TestReached_DoesNotCount(t *testing.T) {
	// Arrange
	l := &Limiter{Period: 24 * time.Hour}
	l.Allow("failed", 2)

	// Act
	before := l.Reached("failed", 2)
	l.Allow("failed", 2)
	after := l.Reached("failed", 2)

	// Assert
	if before || !after || l.keys["failed"].n != 2 {
		t.Fatalf("before=%v after=%v n=%d", before, after, l.keys["failed"].n)
	}
}
