package comments

import (
	"context"
	"io"
	"log/slog"
	"testing"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/llm"
)

// With OpenAI out of credit, every draft went through OpenRouter (20
// requests a minute). A burst of comments hit 429s, each counted as a failed
// attempt, and after three the comments reached the owner unsorted.

type limitedScorer struct {
	calls   int
	limited bool
}

func (s *limitedScorer) Score(context.Context, Comment) (Intent, string, string, error) {
	s.calls++
	if s.limited {
		return "", "", "", &llm.StatusError{Code: 429, Message: "rate limited"}
	}
	return IntentLead, "why", "draft", nil
}

func backoffWorker(store Store, s *limitedScorer, now *time.Time) *Worker {
	return &Worker{Store: store, Scorer: s, Logger: slog.New(slog.NewJSONHandler(io.Discard, nil)),
		Timeout: time.Second, Now: func() time.Time { return *now }}
}

func addNew(t *testing.T, store *Memory, n int) {
	t.Helper()
	for i := range n {
		if _, err := store.Add(context.Background(), Comment{AccountID: 1, CommentID: string(rune('a' + i)), CreatedAt: time.Now()}); err != nil {
			t.Fatal(err)
		}
	}
}

func TestWorker_RateLimitIsNotAFailedAttemptAndStopsThePass(t *testing.T) {
	// Arrange
	ctx := context.Background()
	store := &Memory{}
	addNew(t, store, 3)
	now := time.Date(2026, 11, 11, 0, 0, 0, 0, time.UTC)
	s := &limitedScorer{limited: true}

	// Act
	backoffWorker(store, s, &now).RunOnce(ctx)

	// Assert
	list, _ := store.Unscored(ctx, 10)
	if s.calls != 1 || len(list) != 3 {
		t.Fatalf("calls %d, still new %d (want 1 call, 3 new)", s.calls, len(list))
	}
	for _, c := range list {
		if c.Attempts != 0 {
			t.Fatalf("a 429 counted as a failed attempt: %+v", c)
		}
	}
}

func TestWorker_PausesAfterARateLimitThenResumes(t *testing.T) {
	// Arrange
	ctx := context.Background()
	store := &Memory{}
	addNew(t, store, 2)
	now := time.Date(2026, 11, 11, 0, 0, 0, 0, time.UTC)
	s := &limitedScorer{limited: true}
	w := backoffWorker(store, s, &now)
	w.RunOnce(ctx)

	// Act: too soon, then after the pause with the provider back
	now = now.Add(10 * time.Second)
	w.RunOnce(ctx)
	callsDuringPause := s.calls
	now = now.Add(time.Minute)
	s.limited = false
	n := w.RunOnce(ctx)

	// Assert
	if callsDuringPause != 1 {
		t.Fatalf("scored during the pause: %d calls", callsDuringPause)
	}
	if n != 2 {
		t.Fatalf("after the pause %d scored, want 2", n)
	}
}

func TestWorker_PauseGrowsWhileLimitedAndResetsAfterSuccess(t *testing.T) {
	// Arrange
	ctx := context.Background()
	store := &Memory{}
	addNew(t, store, 1)
	now := time.Date(2026, 11, 11, 0, 0, 0, 0, time.UTC)
	s := &limitedScorer{limited: true}
	w := backoffWorker(store, s, &now)

	// Act
	var pauses []time.Duration
	for range 7 {
		w.RunOnce(ctx)
		pauses = append(pauses, w.pauseUntil.Sub(now))
		now = w.pauseUntil
	}
	s.limited = false
	w.RunOnce(ctx)

	// Assert
	want := []time.Duration{30 * time.Second, time.Minute, 2 * time.Minute, 4 * time.Minute, 8 * time.Minute, 10 * time.Minute, 10 * time.Minute}
	for i := range want {
		if pauses[i] != want[i] {
			t.Fatalf("pause %d = %v, want %v (all %v)", i, pauses[i], want[i], pauses)
		}
	}
	if w.backoff != 0 {
		t.Fatalf("backoff not reset after success: %v", w.backoff)
	}
}
