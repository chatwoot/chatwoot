package memory

import (
	"testing"
	"time"
)

type clock struct{ t time.Time }

func (c *clock) now() time.Time { return c.t }

func TestHistory_TrimsToLimit(t *testing.T) {
	// Arrange
	h := NewHistory(2, time.Hour, nil)

	// Act
	h.Append(1, 7, Turn{"user", "a"})
	h.Append(1, 7, Turn{"assistant", "b"})
	h.Append(1, 7, Turn{"user", "c"})

	// Assert
	got := h.Get(1, 7)
	if len(got) != 2 || got[0].Content != "b" || got[1].Content != "c" {
		t.Errorf("got %+v", got)
	}
}

func TestHistory_SeparatesAccounts(t *testing.T) {
	// Arrange
	h := NewHistory(10, time.Hour, nil)
	h.Append(1, 7, Turn{"user", "acct1"})

	// Act
	got := h.Get(2, 7)

	// Assert
	if got != nil {
		t.Errorf("leaked across accounts: %+v", got)
	}
}

func TestHistory_GetReturnsCopy(t *testing.T) {
	// Arrange
	h := NewHistory(10, time.Hour, nil)
	h.Append(1, 7, Turn{"user", "a"})

	// Act
	got := h.Get(1, 7)
	got[0].Content = "mutated"

	// Assert
	if h.Get(1, 7)[0].Content != "a" {
		t.Error("Get exposed internal slice")
	}
}

func TestHistory_ForgetAndIdleEviction(t *testing.T) {
	// Arrange
	c := &clock{t: time.Unix(0, 0)}
	h := NewHistory(10, time.Hour, c.now)
	h.Append(1, 1, Turn{"user", "old"})
	h.Append(1, 2, Turn{"user", "resolved"})

	// Act
	h.Forget(1, 2)
	c.t = c.t.Add(2 * time.Hour)
	h.Append(1, 3, Turn{"user", "new"})

	// Assert
	if h.Len() != 1 || h.Get(1, 3) == nil {
		t.Errorf("expected only conversation 3, len=%d", h.Len())
	}
}

func TestSeen_DetectsDuplicatesUntilTTL(t *testing.T) {
	// Arrange
	c := &clock{t: time.Unix(0, 0)}
	s := NewSeen(time.Minute, c.now)

	// Act
	first := s.FirstTime("m:1")
	dup := s.FirstTime("m:1")
	c.t = c.t.Add(2 * time.Minute)
	afterTTL := s.FirstTime("m:1")

	// Assert
	if !first || dup || !afterTTL {
		t.Errorf("first=%v dup=%v afterTTL=%v", first, dup, afterTTL)
	}
}

func TestSeen_Release(t *testing.T) {
	// Arrange
	s := NewSeen(time.Hour, nil)
	s.FirstTime("m:2")

	// Act
	s.Release("m:2")

	// Assert
	if !s.FirstTime("m:2") {
		t.Error("released key should be accepted again")
	}
}
