// Package chatwoot is a minimal client for the Chatwoot REST endpoints an
// Agent Bot token may call (see chatwoot app/controllers/concerns/access_token_auth_helper.rb).
package chatwoot

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

// Client calls Chatwoot with an Agent Bot access token.
type Client struct {
	baseURL string
	token   string
	http    *http.Client
}

// New returns a Client. baseURL has no trailing slash, e.g. http://rails:3000.
func New(baseURL, token string, httpClient *http.Client) *Client {
	if httpClient == nil {
		httpClient = &http.Client{Timeout: 15 * time.Second}
	}
	return &Client{baseURL: baseURL, token: token, http: httpClient}
}

// SendMessage posts a public outgoing message to a conversation.
func (c *Client) SendMessage(ctx context.Context, accountID, conversationID int64, content string) error {
	body := map[string]any{"content": content, "message_type": "outgoing", "private": false}
	return c.post(ctx, c.convPath(accountID, conversationID, "/messages"), body)
}

// SendPrivateNote posts a private note visible only to agents.
func (c *Client) SendPrivateNote(ctx context.Context, accountID, conversationID int64, content string) error {
	body := map[string]any{"content": content, "message_type": "outgoing", "private": true}
	return c.post(ctx, c.convPath(accountID, conversationID, "/messages"), body)
}

// Handoff moves a pending conversation to open so human agents see it.
// For bot tokens Chatwoot runs Conversation#bot_handoff! on pending→open.
func (c *Client) Handoff(ctx context.Context, accountID, conversationID int64) error {
	return c.post(ctx, c.convPath(accountID, conversationID, "/toggle_status"), map[string]any{"status": "open"})
}

// SetTyping turns the typing indicator on or off.
func (c *Client) SetTyping(ctx context.Context, accountID, conversationID int64, on bool) error {
	status := "off"
	if on {
		status = "on"
	}
	return c.post(ctx, c.convPath(accountID, conversationID, "/toggle_typing_status"), map[string]any{"typing_status": status})
}

// SetConversationAttributes sets custom attributes on a conversation,
// keeping the ones not named (merge).
func (c *Client) SetConversationAttributes(ctx context.Context, accountID, conversationID int64, attrs map[string]string) error {
	return c.post(ctx, c.convPath(accountID, conversationID, "/custom_attributes"), map[string]any{"custom_attributes": attrs, "merge": true})
}

func (c *Client) convPath(accountID, conversationID int64, suffix string) string {
	return fmt.Sprintf("/api/v1/accounts/%d/conversations/%d%s", accountID, conversationID, suffix)
}

// APIError is a non-2xx response from Chatwoot.
type APIError struct {
	Path   string
	Status int
	Body   string
}

func (e *APIError) Error() string {
	return fmt.Sprintf("chatwoot %s: status %d: %s", e.Path, e.Status, e.Body)
}

func (c *Client) post(ctx context.Context, path string, payload any) error {
	buf, err := json.Marshal(payload)
	if err != nil {
		return err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+path, bytes.NewReader(buf))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("api_access_token", c.token)

	resp, err := c.http.Do(req)
	if err != nil {
		return fmt.Errorf("chatwoot %s: %w", path, err)
	}
	defer resp.Body.Close()
	if resp.StatusCode/100 != 2 {
		snippet, _ := io.ReadAll(io.LimitReader(resp.Body, 512))
		return &APIError{Path: path, Status: resp.StatusCode, Body: string(snippet)}
	}
	_, _ = io.Copy(io.Discard, resp.Body)
	return nil
}
