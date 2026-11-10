package comments

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync/atomic"
	"testing"
	"time"
)

func TestGraph_ReadsAPostsText(t *testing.T) {
	// Arrange
	var gotPath, gotAuth, gotFields string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotPath, gotAuth, gotFields = r.URL.Path, r.Header.Get("Authorization"), r.URL.Query().Get("fields")
		_, _ = w.Write([]byte(`{"id":"1_2","message":"ทุนนวัตกรรมพลังงาน 1,300 ล้านบาท"}`))
	}))
	defer srv.Close()
	g := &Graph{BaseURL: srv.URL, PageID: "1", PageToken: "page-token"}

	// Act
	p, err := g.Post(context.Background(), "1_2")

	// Assert
	if err != nil || p.Text != "ทุนนวัตกรรมพลังงาน 1,300 ล้านบาท" {
		t.Fatalf("got %+v %v", p, err)
	}
	if gotPath != "/1_2" || gotAuth != "Bearer page-token" || !strings.Contains(gotFields, "message") {
		t.Fatalf("request path=%q auth=%q fields=%q", gotPath, gotAuth, gotFields)
	}
}

func TestGraph_PostWithoutTextUsesItsAttachment(t *testing.T) {
	// Arrange: ads and photo posts often have no message.
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		_, _ = w.Write([]byte(`{"id":"1_2","attachments":{"data":[{"title":"John Auto Cut","description":"ตัดคลิปด้วย AI"}]}}`))
	}))
	defer srv.Close()
	g := &Graph{BaseURL: srv.URL, PageID: "1", PageToken: "t"}

	// Act
	p, err := g.Post(context.Background(), "1_2")

	// Assert
	if err != nil || p.Text != "John Auto Cut\nตัดคลิปด้วย AI" {
		t.Fatalf("got %+v %v", p, err)
	}
}

func TestGraph_PostRefusesOddIDsAndHidesTheToken(t *testing.T) {
	// Arrange
	var calls atomic.Int32
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		calls.Add(1)
		w.WriteHeader(http.StatusBadRequest)
		_, _ = w.Write([]byte(`{"error":{"code":100,"message":"bad"}}`))
	}))
	defer srv.Close()
	g := &Graph{BaseURL: srv.URL, PageID: "1", PageToken: "secret-page-token"}

	// Act
	_, oddErr := g.Post(context.Background(), "../me/accounts")
	_, metaErr := g.Post(context.Background(), "1_2")

	// Assert
	if oddErr == nil || calls.Load() != 1 {
		t.Fatalf("odd ID must be refused without a request: err=%v calls=%d", oddErr, calls.Load())
	}
	if metaErr == nil || strings.Contains(metaErr.Error(), "secret-page-token") {
		t.Fatalf("Meta's refusal must be an error without the token: %v", metaErr)
	}
}

type countingPosts struct {
	calls atomic.Int32
	text  string
	err   error
}

func (c *countingPosts) Post(context.Context, string) (Post, error) {
	c.calls.Add(1)
	return Post{Text: c.text}, c.err
}

func TestPostCache_FetchesEachPostOnceUntilItExpires(t *testing.T) {
	// Arrange
	now := time.Date(2026, 11, 11, 0, 0, 0, 0, time.UTC)
	src := &countingPosts{text: "post"}
	c := &PostCache{Reader: src, TTL: time.Hour, Now: func() time.Time { return now }}

	// Act
	for range 5 {
		_, _ = c.Post(context.Background(), "1_2")
	}
	now = now.Add(2 * time.Hour)
	p, err := c.Post(context.Background(), "1_2")

	// Assert
	if err != nil || p.Text != "post" || src.calls.Load() != 2 {
		t.Fatalf("got %+v %v after %d fetches, want 2", p, err, src.calls.Load())
	}
}

func TestPostCache_RemembersFailuresBriefly(t *testing.T) {
	// Arrange: while Graph is down, reloads must not repeat every failing read.
	now := time.Date(2026, 11, 11, 0, 0, 0, 0, time.UTC)
	src := &countingPosts{err: errors.New("graph down")}
	c := &PostCache{Reader: src, TTL: time.Hour, Now: func() time.Time { return now }}

	// Act
	_, err1 := c.Post(context.Background(), "1_2")
	_, err2 := c.Post(context.Background(), "1_2")
	now = now.Add(2 * time.Minute)
	_, err3 := c.Post(context.Background(), "1_2")

	// Assert
	if err1 == nil || err2 == nil || err3 == nil || src.calls.Load() != 2 {
		t.Fatalf("errors %v %v %v, fetches %d (want 2)", err1, err2, err3, src.calls.Load())
	}
}

func TestPostCache_StaysBounded(t *testing.T) {
	// Arrange
	c := &PostCache{Reader: &countingPosts{text: "p"}, TTL: time.Hour, Max: 3}

	// Act
	for _, id := range []string{"1_1", "1_2", "1_3", "1_4", "1_5"} {
		_, _ = c.Post(context.Background(), id)
	}

	// Assert
	if n := c.size(); n > 3 {
		t.Fatalf("cache holds %d posts, max 3", n)
	}
}
