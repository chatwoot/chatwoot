package llm

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func serve(t *testing.T, status int, body string, gotReq *chatRequest, gotAuth *string) *Client {
	t.Helper()
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/chat/completions" {
			t.Errorf("path = %q", r.URL.Path)
		}
		if gotAuth != nil {
			*gotAuth = r.Header.Get("Authorization")
		}
		if gotReq != nil {
			_ = json.NewDecoder(r.Body).Decode(gotReq)
		}
		w.WriteHeader(status)
		_, _ = w.Write([]byte(body))
	}))
	t.Cleanup(srv.Close)
	return New(srv.URL, "k", "test/model", nil)
}

func TestComplete_ReturnsContentAndUsage(t *testing.T) {
	// Arrange
	var req chatRequest
	var auth string
	c := serve(t, 200, `{"model":"test/model-v2","choices":[{"message":{"role":"assistant","content":"  hi there  "}}],"usage":{"prompt_tokens":12,"completion_tokens":3}}`, &req, &auth)

	// Act
	res, err := c.Complete(context.Background(), []Message{{Role: "user", Content: "hello"}})

	// Assert
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if res.Content != "hi there" || res.Model != "test/model-v2" || res.PromptTokens != 12 || res.CompletionTokens != 3 {
		t.Errorf("result = %+v", res)
	}
	if auth != "Bearer k" || req.Model != "test/model" || len(req.Messages) != 1 {
		t.Errorf("auth=%q req=%+v", auth, req)
	}
}

func TestComplete_ErrorStatusIncludesProviderMessage(t *testing.T) {
	// Arrange
	c := serve(t, 402, `{"error":{"message":"insufficient credits"}}`, nil, nil)

	// Act
	_, err := c.Complete(context.Background(), nil)

	// Assert
	if err == nil || !strings.Contains(err.Error(), "402") || !strings.Contains(err.Error(), "insufficient credits") {
		t.Fatalf("err = %v", err)
	}
}

func TestComplete_EmptyChoices(t *testing.T) {
	// Arrange
	c := serve(t, 200, `{"choices":[]}`, nil, nil)

	// Act
	_, err := c.Complete(context.Background(), nil)

	// Assert
	if !errors.Is(err, ErrEmptyResponse) {
		t.Fatalf("err = %v, want ErrEmptyResponse", err)
	}
}

func TestComplete_InvalidJSON(t *testing.T) {
	// Arrange
	c := serve(t, 502, `<html>bad gateway</html>`, nil, nil)

	// Act
	_, err := c.Complete(context.Background(), nil)

	// Assert
	if err == nil || !strings.Contains(err.Error(), "502") {
		t.Fatalf("err = %v", err)
	}
}

func TestComplete_SendsMaxTokensOnlyWhenSet(t *testing.T) {
	// Arrange
	var bodies []map[string]any
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var b map[string]any
		_ = json.NewDecoder(r.Body).Decode(&b)
		bodies = append(bodies, b)
		_, _ = w.Write([]byte(`{"choices":[{"message":{"role":"assistant","content":"ok"}}]}`))
	}))
	defer srv.Close()
	plain := New(srv.URL, "key", "m", nil)
	capped := New(srv.URL, "key", "m", nil)
	capped.MaxTokens = 1024

	// Act
	_, err1 := plain.Complete(context.Background(), []Message{{Role: "user", Content: "hi"}})
	_, err2 := capped.Complete(context.Background(), []Message{{Role: "user", Content: "hi"}})

	// Assert
	if err1 != nil || err2 != nil {
		t.Fatalf("errors: %v %v", err1, err2)
	}
	if _, ok := bodies[0]["max_tokens"]; ok {
		t.Error("no cap must be sent when MaxTokens is 0 (the main model is unchanged)")
	}
	if bodies[1]["max_tokens"] != float64(1024) {
		t.Errorf("max_tokens = %v, want 1024", bodies[1]["max_tokens"])
	}
}

func TestComplete_ErrorStatusIsTyped(t *testing.T) {
	// Arrange
	c := serve(t, 429, `{"error":{"message":"You have no credits remaining."}}`, nil, nil)
	bad := serve(t, 502, `<html>bad gateway</html>`, nil, nil)

	// Act
	_, err := c.Complete(context.Background(), nil)
	_, badErr := bad.Complete(context.Background(), nil)

	// Assert
	var se *StatusError
	if !errors.As(err, &se) || se.Code != 429 || err.Error() != "llm status 429: You have no credits remaining." {
		t.Fatalf("err = %#v", err)
	}
	if !errors.As(badErr, &se) || se.Code != 502 {
		t.Fatalf("invalid JSON error = %#v, want a StatusError with 502", badErr)
	}
	wrapped := fmt.Errorf("primary: %w", err)
	if !IsRateLimited(wrapped) || IsRateLimited(badErr) || IsRateLimited(errors.New("llm status 429")) {
		t.Error("IsRateLimited must match only a typed 429, through wrapping")
	}
}
