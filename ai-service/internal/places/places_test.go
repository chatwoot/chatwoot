package places

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"
)

type fakeStore struct {
	calls int
	err   error
	got   [4]any
}

func (f *fakeStore) Record(_ context.Context, a int64, an string, i int64, in string) error {
	f.calls++
	f.got = [4]any{a, an, i, in}
	return f.err
}
func (f *fakeStore) Accounts(context.Context) ([]Place, error)       { return nil, nil }
func (f *fakeStore) Inboxes(context.Context, int64) ([]Place, error) { return nil, nil }

func TestCleanName(t *testing.T) {
	// Arrange
	cases := map[string]string{
		"  Facebook  Page ":       "Facebook Page",
		"Line\x00OA\nshop":        "Line OA shop",
		"ร้าน John":               "ร้าน John",
		strings.Repeat("ก", 300):  strings.Repeat("ก", MaxName),
		"":                        "",
		"Acme\u202e1# \u200bShop": "Acme 1# Shop",
		"\u2066Inbox\u2069":       "Inbox",
	}
	for in, want := range cases {
		// Act
		got := CleanName(in)

		// Assert
		if got != want {
			t.Errorf("CleanName(%q) = %q, want %q", in, got, want)
		}
	}
}

func TestRecorder_SkipsUnchangedWithinAnHour(t *testing.T) {
	// Arrange
	st := &fakeStore{}
	now := time.Date(2026, 11, 7, 12, 0, 0, 0, time.UTC)
	r := &Recorder{Store: st, Now: func() time.Time { return now }}
	ctx := context.Background()

	// Act
	_ = r.Record(ctx, 1, "Acme", 3, "Website")
	_ = r.Record(ctx, 1, "Acme", 3, "Website")  // same, skipped
	_ = r.Record(ctx, 1, "Acme", 3, "Web chat") // renamed, written
	now = now.Add(61 * time.Minute)
	_ = r.Record(ctx, 1, "Acme", 3, "Web chat") // stale, written
	_ = r.Record(ctx, 0, "x", 3, "y")           // no account, ignored
	_ = r.Record(ctx, 1, "x", 0, "y")           // no inbox, ignored

	// Assert
	if st.calls != 3 {
		t.Errorf("store writes = %d, want 3", st.calls)
	}
}

func TestRecorder_RetriesFailedWriteAfterAMinute(t *testing.T) {
	// Arrange
	st := &fakeStore{err: errors.New("db down")}
	now := time.Date(2026, 11, 7, 12, 0, 0, 0, time.UTC)
	r := &Recorder{Store: st, Now: func() time.Time { return now }}
	ctx := context.Background()

	// Act
	first := r.Record(ctx, 1, "Acme", 3, "Website")
	soon := r.Record(ctx, 1, "Acme", 3, "Website") // within a minute: no new attempt
	st.err = nil
	now = now.Add(61 * time.Second)
	later := r.Record(ctx, 1, "Acme", 3, "Website")
	cached := r.Record(ctx, 1, "Acme", 3, "Website")

	// Assert
	if first == nil || soon != nil || later != nil || cached != nil || st.calls != 2 {
		t.Errorf("first=%v soon=%v later=%v cached=%v calls=%d, want error, nil, nil, nil, 2", first, soon, later, cached, st.calls)
	}
}

func TestRecorder_CleansNamesBeforeStoring(t *testing.T) {
	// Arrange
	st := &fakeStore{}
	r := &Recorder{Store: st}

	// Act
	_ = r.Record(context.Background(), 2, " Acme\n", 5, "\tLine ")

	// Assert
	if st.got != [4]any{int64(2), "Acme", int64(5), "Line"} {
		t.Errorf("stored %v", st.got)
	}
}
