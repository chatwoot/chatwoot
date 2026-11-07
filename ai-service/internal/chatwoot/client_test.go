package chatwoot

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
)

type captured struct {
	path, token string
	body        map[string]any
}

func newServer(t *testing.T, status int, got *captured) *httptest.Server {
	t.Helper()
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		got.path = r.URL.Path
		got.token = r.Header.Get("api_access_token")
		_ = json.NewDecoder(r.Body).Decode(&got.body)
		w.WriteHeader(status)
		_, _ = w.Write([]byte(`{"error":"nope"}`))
	}))
	t.Cleanup(srv.Close)
	return srv
}

func TestSendMessage_PostsPublicOutgoing(t *testing.T) {
	// Arrange
	var got captured
	srv := newServer(t, http.StatusOK, &got)
	c := New(srv.URL, "bot-token", nil)

	// Act
	err := c.SendMessage(context.Background(), 1, 7, "hello")

	// Assert
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got.path != "/api/v1/accounts/1/conversations/7/messages" || got.token != "bot-token" {
		t.Errorf("path=%q token=%q", got.path, got.token)
	}
	if got.body["content"] != "hello" || got.body["private"] != false || got.body["message_type"] != "outgoing" {
		t.Errorf("body = %v", got.body)
	}
}

func TestSendPrivateNote_SetsPrivate(t *testing.T) {
	// Arrange
	var got captured
	c := New(newServer(t, http.StatusOK, &got).URL, "t", nil)

	// Act
	err := c.SendPrivateNote(context.Background(), 1, 7, "note")

	// Assert
	if err != nil || got.body["private"] != true {
		t.Errorf("err=%v body=%v", err, got.body)
	}
}

func TestHandoff_TogglesStatusOpen(t *testing.T) {
	// Arrange
	var got captured
	c := New(newServer(t, http.StatusOK, &got).URL, "t", nil)

	// Act
	err := c.Handoff(context.Background(), 2, 5)

	// Assert
	if err != nil || got.path != "/api/v1/accounts/2/conversations/5/toggle_status" || got.body["status"] != "open" {
		t.Errorf("err=%v path=%q body=%v", err, got.path, got.body)
	}
}

func TestSetTyping_SendsOnOff(t *testing.T) {
	// Arrange
	var got captured
	c := New(newServer(t, http.StatusOK, &got).URL, "t", nil)

	// Act
	err := c.SetTyping(context.Background(), 1, 7, false)

	// Assert
	if err != nil || got.path != "/api/v1/accounts/1/conversations/7/toggle_typing_status" || got.body["typing_status"] != "off" {
		t.Errorf("err=%v path=%q body=%v", err, got.path, got.body)
	}
}

func TestPost_ReturnsAPIErrorOnNon2xx(t *testing.T) {
	// Arrange
	var got captured
	c := New(newServer(t, http.StatusUnauthorized, &got).URL, "bad", nil)

	// Act
	err := c.SendMessage(context.Background(), 1, 7, "x")

	// Assert
	var apiErr *APIError
	if !errors.As(err, &apiErr) || apiErr.Status != http.StatusUnauthorized {
		t.Fatalf("expected APIError 401, got %v", err)
	}
}

func TestSetConversationAttributes_MergesOnly(t *testing.T) {
	// Arrange
	var got captured
	c := New(newServer(t, http.StatusOK, &got).URL, "t", nil)

	// Act
	err := c.SetConversationAttributes(context.Background(), 1, 7, map[string]string{"customer_email": "a@gmail.com"})

	// Assert
	attrs, _ := got.body["custom_attributes"].(map[string]any)
	if err != nil || got.path != "/api/v1/accounts/1/conversations/7/custom_attributes" || got.body["merge"] != true || attrs["customer_email"] != "a@gmail.com" {
		t.Fatalf("err=%v path=%q body=%v", err, got.path, got.body)
	}
}
