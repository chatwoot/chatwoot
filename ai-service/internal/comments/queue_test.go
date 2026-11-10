package comments

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func TestGraph_SendsAPrivateReply(t *testing.T) {
	// Arrange
	var gotPath, gotAuth, gotRawQuery string
	var gotBody map[string]map[string]string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotPath, gotAuth, gotRawQuery = r.URL.Path, r.Header.Get("Authorization"), r.URL.RawQuery
		_ = json.NewDecoder(r.Body).Decode(&gotBody)
		_, _ = io.WriteString(w, `{"recipient_id":"1","message_id":"m"}`)
	}))
	defer srv.Close()
	g := &Graph{BaseURL: srv.URL + "/v24.0", PageID: testPage, PageToken: "page-token-xyz"}

	// Act
	err := g.SendPrivateReply(context.Background(), "2222_3333", "สวัสดีค่ะ")

	// Assert
	if err != nil || gotPath != "/v24.0/1111/messages" || gotAuth != "Bearer page-token-xyz" || gotRawQuery != "" {
		t.Fatalf("err %v path %q auth %q query %q", err, gotPath, gotAuth, gotRawQuery)
	}
	if gotBody["recipient"]["comment_id"] != "2222_3333" || gotBody["message"]["text"] != "สวัสดีค่ะ" {
		t.Fatalf("body %+v", gotBody)
	}
}

func TestGraph_RefusalsAreTypedAndHideTheToken(t *testing.T) {
	cases := map[string]struct {
		status    int
		body      string
		permanent bool
	}{
		"already replied": {400, `{"error":{"code":10900,"message":"Activity already replied to"}}`, true},
		"too old":         {400, `{"error":{"code":10903,"message":"This activity can't be replied to"}}`, true},
		"bad token":       {400, `{"error":{"code":190,"message":"Invalid OAuth access token"}}`, false},
		"server error":    {502, `bad gateway`, false},
	}
	for name, c := range cases {
		t.Run(name, func(t *testing.T) {
			// Arrange
			srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
				w.WriteHeader(c.status)
				_, _ = io.WriteString(w, c.body)
			}))
			defer srv.Close()
			g := &Graph{BaseURL: srv.URL, PageID: testPage, PageToken: "page-token-xyz"}

			// Act
			err := g.SendPrivateReply(context.Background(), "c", "hi")

			// Assert
			var se *SendError
			if !errors.As(err, &se) || se.Permanent != c.permanent || strings.Contains(err.Error(), "page-token-xyz") {
				t.Fatalf("err %v", err)
			}
		})
	}
}

type fakeSender struct {
	calls []string
	err   error
}

func (f *fakeSender) SendPrivateReply(_ context.Context, commentID, text string) error {
	f.calls = append(f.calls, commentID+"|"+text)
	return f.err
}

var now = time.Date(2026, 11, 10, 12, 0, 0, 0, time.UTC)

// waitingComment stores a scored comment and returns it.
func waitingComment(t *testing.T, store Store, created time.Time) Comment {
	t.Helper()
	ctx := context.Background()
	if _, err := store.Add(ctx, Comment{AccountID: 2, PageID: testPage, CommentID: "c-" + created.Format("150405.000"), FromID: "9", CreatedAt: created}); err != nil {
		t.Fatal(err)
	}
	list, _ := store.Unscored(ctx, 1)
	if err := store.Score(ctx, list[0].ID, IntentLead, "asks the price", "draft"); err != nil {
		t.Fatal(err)
	}
	c, _ := store.Get(ctx, 2, list[0].ID)
	return c
}

func TestQueue_SendSendsOnceAndRecordsIt(t *testing.T) {
	// Arrange
	ctx := context.Background()
	store, sender := &Memory{}, &fakeSender{}
	q := &Queue{Store: store, Sender: sender, Now: func() time.Time { return now }}
	c := waitingComment(t, store, now.Add(-time.Hour))

	// Act
	err1 := q.Send(ctx, 2, c.ID, c.Version, "  Hello  ", "owner@example.com")
	err2 := q.Send(ctx, 2, c.ID, c.Version, "Hello", "owner@example.com")

	// Assert
	got, _ := store.Get(ctx, 2, c.ID)
	if err1 != nil || !errors.Is(err2, ErrChanged) || len(sender.calls) != 1 || sender.calls[0] != c.CommentID+"|Hello" {
		t.Fatalf("errs %v %v calls %v", err1, err2, sender.calls)
	}
	if got.Status != StatusSent || got.Reply != "Hello" || got.DecidedBy != "owner@example.com" {
		t.Fatalf("row %+v", got)
	}
}

func TestQueue_SendRefusesWithoutSending(t *testing.T) {
	cases := map[string]struct {
		text    string
		created time.Time
		version int // 0: the current one
		acct    int64
		noToken bool
		want    error
	}{
		"empty":         {text: "   ", created: now, want: ErrEmptyReply},
		"too long":      {text: strings.Repeat("a", MaxReplyRunes+1), created: now, want: ErrLongReply},
		"expired":       {text: "Hi", created: now.Add(-ReplyWindow - time.Minute), want: ErrExpired},
		"stale version": {text: "Hi", created: now, version: 99, want: ErrChanged},
		"other account": {text: "Hi", created: now, acct: 3, want: ErrNotFound},
		"no page token": {text: "Hi", created: now, noToken: true, want: ErrSendingOff},
	}
	for name, c := range cases {
		t.Run(name, func(t *testing.T) {
			// Arrange
			store, sender := &Memory{}, &fakeSender{}
			q := &Queue{Store: store, Sender: sender, Now: func() time.Time { return now }}
			if c.noToken {
				q.Sender = nil
			}
			row := waitingComment(t, store, c.created)
			version, acct := row.Version, int64(2)
			if c.version != 0 {
				version = c.version
			}
			if c.acct != 0 {
				acct = c.acct
			}

			// Act
			err := q.Send(context.Background(), acct, row.ID, version, c.text, "owner")

			// Assert
			after, _ := store.Get(context.Background(), 2, row.ID)
			if !errors.Is(err, c.want) || len(sender.calls) != 0 || after.Status != StatusWaiting {
				t.Fatalf("err %v calls %v status %s", err, sender.calls, after.Status)
			}
		})
	}
}

func TestQueue_PermanentRefusalMarksFailed(t *testing.T) {
	// Arrange
	ctx := context.Background()
	store := &Memory{}
	q := &Queue{Store: store, Sender: &fakeSender{err: &SendError{Code: 10900, Message: "Activity already replied to", Permanent: true}}, Now: func() time.Time { return now }}
	c := waitingComment(t, store, now)

	// Act
	err := q.Send(ctx, 2, c.ID, c.Version, "Hi", "owner")

	// Assert
	got, _ := store.Get(ctx, 2, c.ID)
	if !errors.Is(err, ErrSendRefused) || got.Status != StatusFailed || !strings.Contains(got.Error, "10900") {
		t.Fatalf("err %v row %+v", err, got)
	}
}

func TestQueue_TemporaryFailureWaitsAgain(t *testing.T) {
	// Arrange
	ctx := context.Background()
	store := &Memory{}
	sender := &fakeSender{err: errors.New("timeout")}
	q := &Queue{Store: store, Sender: sender, Now: func() time.Time { return now }}
	c := waitingComment(t, store, now)
	_ = q.Send(ctx, 2, c.ID, c.Version, "Hi", "owner")
	failed, _ := store.Get(ctx, 2, c.ID)
	sender.err = nil

	// Act
	err := q.Send(ctx, 2, c.ID, failed.Version, "Hi", "owner")

	// Assert
	got, _ := store.Get(ctx, 2, c.ID)
	if failed.Status != StatusWaiting || failed.Error != "timeout" || err != nil || got.Status != StatusSent || got.Error != "" {
		t.Fatalf("failed %+v got %+v err %v", failed, got, err)
	}
}

func TestQueue_Dismiss(t *testing.T) {
	// Arrange
	ctx := context.Background()
	store := &Memory{}
	q := &Queue{Store: store, Sender: &fakeSender{}, Now: func() time.Time { return now }}
	c := waitingComment(t, store, now)

	// Act
	stale := q.Dismiss(ctx, 2, c.ID, c.Version+1, "owner")
	err := q.Dismiss(ctx, 2, c.ID, c.Version, "owner")

	// Assert
	got, _ := store.Get(ctx, 2, c.ID)
	waiting, _ := q.Waiting(ctx, 2)
	if !errors.Is(stale, ErrChanged) || err != nil || got.Status != StatusDismissed || len(waiting) != 0 {
		t.Fatalf("stale %v err %v row %+v", stale, err, got)
	}
}

func TestGraph_NetworkErrorNamesTheHostOnly(t *testing.T) {
	// Arrange: nothing listens on this port
	g := &Graph{BaseURL: "http://127.0.0.1:1/v24.0", PageID: testPage, PageToken: "page-token-xyz"}

	// Act
	err := g.SendPrivateReply(context.Background(), "c", "hi")

	// Assert
	if err == nil || !strings.Contains(err.Error(), "127.0.0.1:1") || strings.Contains(err.Error(), "/messages") || strings.Contains(err.Error(), "page-token-xyz") {
		t.Fatalf("err %v", err)
	}
}

// brokenFinish loses the record of a send.
type brokenFinish struct{ Memory }

func (*brokenFinish) Finish(context.Context, int64, Status, string, string, string) error {
	return errors.New("db down")
}

func TestQueue_SentButNotRecordedIsReportedAsSuch(t *testing.T) {
	// Arrange
	ctx := context.Background()
	store, sender := &brokenFinish{}, &fakeSender{}
	q := &Queue{Store: store, Sender: sender, Now: func() time.Time { return now }}
	c := waitingComment(t, store, now)

	// Act
	err := q.Send(ctx, 2, c.ID, c.Version, "Hi", "owner")
	again := q.Send(ctx, 2, c.ID, c.Version, "Hi", "owner")

	// Assert
	if !errors.Is(err, ErrNotRecorded) || !errors.Is(again, ErrChanged) || len(sender.calls) != 1 {
		t.Fatalf("err %v again %v calls %d", err, again, len(sender.calls))
	}
}
