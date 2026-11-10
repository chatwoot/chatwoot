package comments

import (
	"crypto/hmac"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"encoding/json"
	"errors"
	"regexp"
	"strconv"
	"strings"
	"time"
)

// Signature errors.
var (
	ErrMissingSignature = errors.New("missing X-Hub-Signature-256")
	ErrBadSignature     = errors.New("signature mismatch")
)

// VerifySignature checks Meta's webhook signature:
// X-Hub-Signature-256 = "sha256=" + hex(HMAC-SHA256(app secret, raw body)).
// https://developers.facebook.com/docs/graph-api/webhooks/getting-started#validate-payloads
// Meta signs no timestamp, so replays are stopped by storing each comment ID
// once (Store.Add), not here.
func VerifySignature(appSecret, header string, body []byte) error {
	if header == "" {
		return ErrMissingSignature
	}
	got, ok := strings.CutPrefix(header, "sha256=")
	if !ok {
		return ErrBadSignature
	}
	gotBytes, err := hex.DecodeString(got)
	if err != nil {
		return ErrBadSignature
	}
	mac := hmac.New(sha256.New, []byte(appSecret))
	mac.Write(body)
	if !hmac.Equal(gotBytes, mac.Sum(nil)) {
		return ErrBadSignature
	}
	return nil
}

// Sign returns the X-Hub-Signature-256 header value for body (tests).
func Sign(appSecret string, body []byte) string {
	mac := hmac.New(sha256.New, []byte(appSecret))
	mac.Write(body)
	return "sha256=" + hex.EncodeToString(mac.Sum(nil))
}

// challengeRe bounds what the handshake echoes back. Meta sends a number;
// anything else is refused so the endpoint cannot reflect arbitrary text.
var challengeRe = regexp.MustCompile(`^[A-Za-z0-9_-]{1,128}$`)

// Handshake answers Meta's subscription check (GET with hub.mode,
// hub.verify_token and hub.challenge). It returns the challenge to echo, or
// false when the request is not a valid check for this verify token.
func Handshake(verifyToken, mode, token, challenge string) (string, bool) {
	if verifyToken == "" || mode != "subscribe" || !challengeRe.MatchString(challenge) {
		return "", false
	}
	if subtle.ConstantTimeCompare([]byte(token), []byte(verifyToken)) != 1 {
		return "", false
	}
	return challenge, true
}

// Change is one comment event for the Page, as Parse found it.
type Change struct {
	Verb    string // "add" or "remove" (edits are skipped)
	Comment Comment
}

type feedPayload struct {
	Object string `json:"object"`
	Entry  []struct {
		ID      string `json:"id"`
		Changes []struct {
			Field string `json:"field"`
			Value struct {
				Item        string      `json:"item"`
				Verb        string      `json:"verb"`
				CommentID   string      `json:"comment_id"`
				PostID      string      `json:"post_id"`
				ParentID    string      `json:"parent_id"`
				Message     string      `json:"message"`
				CreatedTime json.Number `json:"created_time"`
				From        struct {
					ID   string `json:"id"`
					Name string `json:"name"`
				} `json:"from"`
			} `json:"value"`
		} `json:"changes"`
	} `json:"entry"`
}

// Parse reads a Page webhook body and returns the comment events for pageID:
// new comments by people (not by the Page itself) and deleted comments.
// Other events (likes, posts, edits, other Pages) are skipped.
func Parse(body []byte, pageID string) ([]Change, error) {
	var p feedPayload
	if err := json.Unmarshal(body, &p); err != nil {
		return nil, err
	}
	if p.Object != "page" {
		return nil, nil
	}
	var out []Change
	for _, e := range p.Entry {
		if e.ID != pageID {
			continue
		}
		for _, ch := range e.Changes {
			v := ch.Value
			if ch.Field != "feed" || v.Item != "comment" || v.CommentID == "" {
				continue
			}
			if !idsFit(v.CommentID, v.PostID, v.ParentID, v.From.ID) {
				continue // the database would refuse the row and Meta would retry it forever
			}
			switch v.Verb {
			case "remove":
				out = append(out, Change{Verb: "remove", Comment: Comment{PageID: pageID, CommentID: v.CommentID}})
			case "add":
				if v.From.ID == "" || v.From.ID == pageID {
					continue // the Page's own comments are never leads
				}
				out = append(out, Change{Verb: "add", Comment: Comment{
					PageID: pageID, CommentID: v.CommentID, PostID: v.PostID, ParentID: v.ParentID,
					FromID: v.From.ID, FromName: clip(noNUL(v.From.Name), 256), Message: clip(noNUL(v.Message), MaxMessageRunes),
					CreatedAt: unixTime(v.CreatedTime),
				}})
			}
		}
	}
	return out, nil
}

// idsFit reports whether Meta's IDs fit the table: 128 characters for the
// comment and post IDs, 64 for the person's ID, and no NUL character.
func idsFit(commentID, postID, parentID, fromID string) bool {
	for _, id := range []string{commentID, postID, parentID} {
		if len(id) > 128 || strings.ContainsRune(id, 0) {
			return false
		}
	}
	return len(fromID) <= 64 && !strings.ContainsRune(fromID, 0)
}

// noNUL drops NUL characters, which Postgres text cannot hold.
func noNUL(s string) string { return strings.ReplaceAll(s, "\x00", "") }

// unixTime reads Meta's created_time (seconds). A missing or odd value means
// now, so the reply window is not shortened by a bad timestamp.
func unixTime(n json.Number) time.Time {
	sec, err := strconv.ParseInt(n.String(), 10, 64)
	if err != nil || sec <= 0 {
		return time.Now()
	}
	return time.Unix(sec, 0)
}

// clip cuts s to at most n runes.
func clip(s string, n int) string {
	r := []rune(s)
	if len(r) <= n {
		return s
	}
	return string(r[:n])
}
