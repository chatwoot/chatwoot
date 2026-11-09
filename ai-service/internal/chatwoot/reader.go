package chatwoot

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"sync"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/memory"
)

// Reader reads a conversation's recent messages. Chatwoot does not let Agent
// Bot tokens list messages, so it uses an agent account's token (the "AI
// Reader" user, with access only to the bot's inboxes).
type Reader struct {
	baseURL string
	token   string
	http    *http.Client

	mu   sync.Mutex
	self int64 // the reader account's user id, once known
}

// NewReader returns a Reader. baseURL has no trailing slash.
func NewReader(baseURL, token string, httpClient *http.Client) *Reader {
	if httpClient == nil {
		httpClient = &http.Client{Timeout: 10 * time.Second}
	}
	return &Reader{baseURL: baseURL, token: token, http: httpClient}
}

type listedMessage struct {
	ID          int64             `json:"id"`
	MessageType int               `json:"message_type"` // 0 incoming, 1 outgoing, 2 activity, 3 template
	Private     bool              `json:"private"`
	Content     string            `json:"content"`
	Attachments []json.RawMessage `json:"attachments"`
	Sender      *struct {
		Type string `json:"type"`
	} `json:"sender"`
	ContentAttributes struct {
		ExternalEcho bool `json:"external_echo"`
	} `json:"content_attributes"`
}

// RecentTurns returns the conversation's latest messages (Chatwoot's newest
// page, oldest first) as chat turns: customer messages as "user", public
// replies from the bot or staff (Messenger echoes included) as "assistant".
// Private notes, activity messages and the message skipID are left out.
func (r *Reader) RecentTurns(ctx context.Context, accountID, conversationID, skipID int64) ([]memory.Turn, error) {
	path := fmt.Sprintf("/api/v1/accounts/%d/conversations/%d/messages", accountID, conversationID)
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, r.baseURL+path, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("api_access_token", r.token)
	resp, err := r.http.Do(req)
	if err != nil {
		return nil, fmt.Errorf("chatwoot %s: %w", path, err)
	}
	defer resp.Body.Close()
	if resp.StatusCode/100 != 2 {
		snippet, _ := io.ReadAll(io.LimitReader(resp.Body, 512))
		return nil, &APIError{Path: path, Status: resp.StatusCode, Body: string(snippet)}
	}
	var page struct {
		Payload []listedMessage `json:"payload"`
	}
	if err := json.NewDecoder(io.LimitReader(resp.Body, 4<<20)).Decode(&page); err != nil {
		return nil, fmt.Errorf("chatwoot %s: %w", path, err)
	}
	var turns []memory.Turn
	botSpoke := false
	for _, m := range page.Payload {
		t, ok := toTurn(m, skipID)
		if !ok {
			continue
		}
		// An echo before the bot's first reply is the page's own automatic
		// message (Instant Reply, an ad's welcome); later echoes are admins.
		if m.ContentAttributes.ExternalEcho && !botSpoke {
			t.Content = memory.PageMessagePrefix + t.Content
		}
		if m.Sender != nil && m.Sender.Type == "agent_bot" {
			botSpoke = true
		}
		turns = append(turns, t)
	}
	return turns, nil
}

func toTurn(m listedMessage, skipID int64) (memory.Turn, bool) {
	if m.Private || m.ID == skipID || (m.MessageType != 0 && m.MessageType != 1) {
		return memory.Turn{}, false
	}
	role := "user"
	if m.MessageType == 1 {
		role = "assistant"
	}
	content := m.Content
	if content == "" {
		if role == "assistant" || len(m.Attachments) == 0 {
			return memory.Turn{}, false
		}
		content = "[The customer sent a file]"
	}
	return memory.Turn{Role: role, Content: content}, true
}

// Staff is an inbox member as the assignment step sees them.
type Staff struct {
	ID     int64
	Name   string
	Online bool
	Reader bool // the reader account itself: never given chats
}

// InboxStaff lists an inbox's members and whether each is online now
// (Chatwoot's live presence, the same signal its own auto-assignment uses).
func (r *Reader) InboxStaff(ctx context.Context, accountID, inboxID int64) ([]Staff, error) {
	var page struct {
		Payload []struct {
			ID                 int64  `json:"id"`
			Name               string `json:"name"`
			AvailabilityStatus string `json:"availability_status"`
		} `json:"payload"`
	}
	if err := r.getJSON(ctx, fmt.Sprintf("/api/v1/accounts/%d/inbox_members/%d", accountID, inboxID), nil, &page); err != nil {
		return nil, err
	}
	self, err := r.selfID(ctx)
	if err != nil {
		return nil, err
	}
	staff := make([]Staff, 0, len(page.Payload))
	for _, m := range page.Payload {
		staff = append(staff, Staff{ID: m.ID, Name: m.Name, Online: m.AvailabilityStatus == "online", Reader: m.ID == self})
	}
	return staff, nil
}

// selfID is the reader account's own user id (asked once, then kept).
func (r *Reader) selfID(ctx context.Context) (int64, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if r.self != 0 {
		return r.self, nil
	}
	var profile struct {
		ID int64 `json:"id"`
	}
	if err := r.getJSON(ctx, "/api/v1/profile", nil, &profile); err != nil {
		return 0, err
	}
	r.self = profile.ID
	return r.self, nil
}

// OpenCount is how many open conversations are assigned to a user.
func (r *Reader) OpenCount(ctx context.Context, accountID, userID int64) (int, error) {
	filter := map[string]any{"payload": []map[string]any{
		{"attribute_key": "status", "filter_operator": "equal_to", "values": []string{"open"}, "query_operator": "and"},
		{"attribute_key": "assignee_id", "filter_operator": "equal_to", "values": []int64{userID}, "query_operator": nil},
	}}
	var res struct {
		Meta struct {
			AllCount int `json:"all_count"`
		} `json:"meta"`
	}
	if err := r.getJSON(ctx, fmt.Sprintf("/api/v1/accounts/%d/conversations/filter", accountID), filter, &res); err != nil {
		return 0, err
	}
	return res.Meta.AllCount, nil
}

// Assignee returns the staff member (a user) a conversation is assigned to,
// or 0. While the bot handles a chat Chatwoot reports the agent bot as its
// assignee, and a bot's id can equal a user's, so only a User counts.
func (r *Reader) Assignee(ctx context.Context, accountID, conversationID int64) (int64, error) {
	var conv struct {
		Meta struct {
			Assignee *struct {
				ID int64 `json:"id"`
			} `json:"assignee"`
			AssigneeType string `json:"assignee_type"`
		} `json:"meta"`
	}
	if err := r.getJSON(ctx, fmt.Sprintf("/api/v1/accounts/%d/conversations/%d", accountID, conversationID), nil, &conv); err != nil {
		return 0, err
	}
	if conv.Meta.Assignee == nil || conv.Meta.AssigneeType != "User" {
		return 0, nil
	}
	return conv.Meta.Assignee.ID, nil
}

// getJSON GETs path (or POSTs body when it is not nil) and decodes the reply.
func (r *Reader) getJSON(ctx context.Context, path string, body any, out any) error {
	method, reader := http.MethodGet, io.Reader(nil)
	if body != nil {
		buf, err := json.Marshal(body)
		if err != nil {
			return err
		}
		method, reader = http.MethodPost, bytes.NewReader(buf)
	}
	req, err := http.NewRequestWithContext(ctx, method, r.baseURL+path, reader)
	if err != nil {
		return err
	}
	req.Header.Set("api_access_token", r.token)
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	resp, err := r.http.Do(req)
	if err != nil {
		return fmt.Errorf("chatwoot %s: %w", path, err)
	}
	defer resp.Body.Close()
	if resp.StatusCode/100 != 2 {
		snippet, _ := io.ReadAll(io.LimitReader(resp.Body, 512))
		return &APIError{Path: path, Status: resp.StatusCode, Body: string(snippet)}
	}
	if err := json.NewDecoder(io.LimitReader(resp.Body, 4<<20)).Decode(out); err != nil {
		return fmt.Errorf("chatwoot %s: %w", path, err)
	}
	return nil
}
