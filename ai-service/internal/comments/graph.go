package comments

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"time"
)

// DefaultGraphVersion is the Graph API version used when none is set.
const DefaultGraphVersion = "v24.0"

// Graph sends private replies through Meta's Send API:
// POST /{page-id}/messages with recipient {comment_id}.
type Graph struct {
	BaseURL   string // https://graph.facebook.com/v24.0; tests point it elsewhere
	PageID    string
	PageToken string // a Page access token with pages_messaging (secret)
	Client    *http.Client
}

// SendError is Meta's refusal of a private reply.
type SendError struct {
	Code    int
	Message string
	// Permanent: Meta will never accept a reply to this comment (already
	// replied, too old, deleted, person unavailable).
	Permanent bool
}

func (e *SendError) Error() string {
	return fmt.Sprintf("meta refused the reply (code %d): %s", e.Code, e.Message)
}

// permanentCodes are Send API errors that a retry cannot fix.
// 10900: activity already replied to; 10903: activity can't be replied to
// (too old or deleted); 551: this person isn't available right now.
var permanentCodes = map[int]bool{10900: true, 10903: true, 551: true}

// SendPrivateReply sends text to the person who wrote commentID.
func (g *Graph) SendPrivateReply(ctx context.Context, commentID, text string) error {
	body, err := json.Marshal(map[string]any{
		"recipient": map[string]string{"comment_id": commentID},
		"message":   map[string]string{"text": text},
	})
	if err != nil {
		return err
	}
	endpoint := g.BaseURL + "/" + url.PathEscape(g.PageID) + "/messages"
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, bytes.NewReader(body))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	// The token goes in a header, never the URL, so it cannot reach a log.
	req.Header.Set("Authorization", "Bearer "+g.PageToken)
	client := g.Client
	if client == nil {
		client = &http.Client{Timeout: 20 * time.Second}
	}
	res, err := client.Do(req)
	if err != nil {
		// Keep the host, not the full URL, out of logs and the admin page.
		var ue *url.Error
		if errors.As(err, &ue) {
			err = ue.Err
		}
		return fmt.Errorf("send private reply via %s: %w", req.URL.Host, err)
	}
	defer res.Body.Close()
	raw, _ := io.ReadAll(io.LimitReader(res.Body, 64<<10))
	if res.StatusCode/100 == 2 {
		return nil
	}
	var e struct {
		Error struct {
			Code    int    `json:"code"`
			Message string `json:"message"`
		} `json:"error"`
	}
	if json.Unmarshal(raw, &e) != nil || e.Error.Code == 0 {
		return &SendError{Code: res.StatusCode, Message: http.StatusText(res.StatusCode)}
	}
	return &SendError{Code: e.Error.Code, Message: clip(e.Error.Message, 300), Permanent: permanentCodes[e.Error.Code]}
}
