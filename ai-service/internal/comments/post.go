package comments

// The post a comment was left on. Without it the drafter only sees "สนใจ"
// and the business profile, so every interested comment gets the same pitch
// whatever the post was about. Issue: DEV-Johnstocker/chatwoot#1

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"sync"
	"time"
)

// MaxPostRunes caps the post text given to the model and shown on the queue.
const MaxPostRunes = 1500

// Post is the part of a Page post the drafter needs.
type Post struct {
	ID   string
	Text string // the message, or the attachment's title and description
}

// PostReader reads one Page post.
type PostReader interface {
	Post(ctx context.Context, postID string) (Post, error)
}

// ErrBadPostID means the ID is not a Meta post ID ("<page>_<post>", digits).
var ErrBadPostID = errors.New("not a Facebook post ID")

// validPostID accepts only digits and underscores, so an ID from a webhook
// can never change the Graph path.
func validPostID(id string) bool {
	if id == "" || len(id) > 128 {
		return false
	}
	for _, r := range id {
		if (r < '0' || r > '9') && r != '_' {
			return false
		}
	}
	return true
}

// Post reads a post's text with the Page token (pages_read_engagement):
// GET /{post-id}?fields=message,attachments{title,description}.
func (g *Graph) Post(ctx context.Context, postID string) (Post, error) {
	if !validPostID(postID) {
		return Post{}, ErrBadPostID
	}
	endpoint := g.BaseURL + "/" + postID + "?fields=" + url.QueryEscape("message,attachments{title,description}")
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return Post{}, err
	}
	req.Header.Set("Authorization", "Bearer "+g.PageToken)
	client := g.Client
	if client == nil {
		client = &http.Client{Timeout: 10 * time.Second}
	}
	res, err := client.Do(req)
	if err != nil {
		var ue *url.Error
		if errors.As(err, &ue) {
			err = ue.Err
		}
		return Post{}, fmt.Errorf("read post via %s: %w", req.URL.Host, err)
	}
	defer res.Body.Close()
	raw, _ := io.ReadAll(io.LimitReader(res.Body, 256<<10))
	var body struct {
		Message     string `json:"message"`
		Attachments struct {
			Data []struct {
				Title       string `json:"title"`
				Description string `json:"description"`
			} `json:"data"`
		} `json:"attachments"`
		Error struct {
			Code    int    `json:"code"`
			Message string `json:"message"`
		} `json:"error"`
	}
	if err := json.Unmarshal(raw, &body); err != nil {
		return Post{}, fmt.Errorf("read post: status %d", res.StatusCode)
	}
	if res.StatusCode/100 != 2 {
		return Post{}, fmt.Errorf("read post: meta code %d: %s", body.Error.Code, clip(body.Error.Message, 200))
	}
	text := strings.TrimSpace(body.Message)
	if text == "" {
		var parts []string
		for _, a := range body.Attachments.Data {
			for _, s := range []string{a.Title, a.Description} {
				if s = strings.TrimSpace(s); s != "" {
					parts = append(parts, s)
				}
			}
		}
		text = strings.Join(parts, "\n")
	}
	return Post{ID: postID, Text: clip(noNUL(text), MaxPostRunes)}, nil
}

// PostCache remembers posts it read, so many comments on one post cost one
// Graph call. A failed read is remembered for FailTTL, so a Graph outage is
// not hit again on every page load; a read cut short by the caller's own
// deadline is not remembered.
type PostCache struct {
	Reader  PostReader
	TTL     time.Duration    // default 1 hour
	FailTTL time.Duration    // default 1 minute
	Max     int              // default 500 posts
	Now     func() time.Time // tests

	mu sync.Mutex
	m  map[string]cachedPost
}

type cachedPost struct {
	post Post
	err  error
	at   time.Time
}

func (c *PostCache) now() time.Time {
	if c.Now != nil {
		return c.Now()
	}
	return time.Now()
}

// Post returns the post from the cache, or reads and remembers it.
func (c *PostCache) Post(ctx context.Context, postID string) (Post, error) {
	ttl, failTTL, max := c.TTL, c.FailTTL, c.Max
	if ttl <= 0 {
		ttl = time.Hour
	}
	if failTTL <= 0 {
		failTTL = time.Minute
	}
	if max <= 0 {
		max = 500
	}
	c.mu.Lock()
	if e, ok := c.m[postID]; ok {
		age := c.now().Sub(e.at)
		if e.err == nil && age < ttl {
			c.mu.Unlock()
			return e.post, nil
		}
		if e.err != nil && age < failTTL {
			c.mu.Unlock()
			return Post{}, e.err
		}
	}
	c.mu.Unlock()
	p, err := c.Reader.Post(ctx, postID)
	if err != nil && ctx.Err() != nil {
		return Post{}, err // our caller gave up; Graph may be fine
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.m == nil {
		c.m = map[string]cachedPost{}
	}
	if _, ok := c.m[postID]; !ok && len(c.m) >= max {
		c.evictOldest()
	}
	c.m[postID] = cachedPost{post: p, err: err, at: c.now()}
	return p, err
}

func (c *PostCache) evictOldest() {
	var oldest string
	var at time.Time
	for id, e := range c.m {
		if oldest == "" || e.at.Before(at) {
			oldest, at = id, e.at
		}
	}
	delete(c.m, oldest)
}

func (c *PostCache) size() int {
	c.mu.Lock()
	defer c.mu.Unlock()
	return len(c.m)
}
