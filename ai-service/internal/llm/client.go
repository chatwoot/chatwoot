// Package llm calls an OpenAI-compatible chat completions API (OpenRouter by default).
package llm

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
)

// Message is one chat turn. Role is "system", "user" or "assistant".
type Message struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

// Result is a completion plus the usage data we log for cost tracking.
type Result struct {
	Content          string
	Model            string
	PromptTokens     int
	CompletionTokens int
	UsedFallback     bool // set by Fallback when the secondary provider answered
}

// Client talks to {baseURL}/chat/completions.
type Client struct {
	baseURL string
	apiKey  string
	model   string
	http    *http.Client
}

// New returns a Client. httpClient should carry the request timeout.
func New(baseURL, apiKey, model string, httpClient *http.Client) *Client {
	if httpClient == nil {
		httpClient = http.DefaultClient
	}
	return &Client{baseURL: baseURL, apiKey: apiKey, model: model, http: httpClient}
}

// ErrEmptyResponse means the API returned no usable text.
var ErrEmptyResponse = errors.New("llm returned empty response")

type chatRequest struct {
	Model    string    `json:"model"`
	Messages []Message `json:"messages"`
}

type chatResponse struct {
	Model   string `json:"model"`
	Choices []struct {
		Message Message `json:"message"`
	} `json:"choices"`
	Usage struct {
		PromptTokens     int `json:"prompt_tokens"`
		CompletionTokens int `json:"completion_tokens"`
	} `json:"usage"`
	Error *struct {
		Message string `json:"message"`
	} `json:"error"`
}

// Complete sends messages and returns the first choice.
func (c *Client) Complete(ctx context.Context, messages []Message) (Result, error) {
	buf, err := json.Marshal(chatRequest{Model: c.model, Messages: messages})
	if err != nil {
		return Result{}, err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+"/chat/completions", bytes.NewReader(buf))
	if err != nil {
		return Result{}, err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+c.apiKey)
	req.Header.Set("X-Title", "chatwoot-ai-service")

	resp, err := c.http.Do(req)
	if err != nil {
		return Result{}, fmt.Errorf("llm request: %w", err)
	}
	defer resp.Body.Close()
	raw, err := io.ReadAll(io.LimitReader(resp.Body, 4<<20))
	if err != nil {
		return Result{}, fmt.Errorf("llm read: %w", err)
	}

	var parsed chatResponse
	if err := json.Unmarshal(raw, &parsed); err != nil {
		return Result{}, fmt.Errorf("llm status %d: invalid json", resp.StatusCode)
	}
	if resp.StatusCode/100 != 2 || parsed.Error != nil {
		msg := ""
		if parsed.Error != nil {
			msg = parsed.Error.Message
		}
		return Result{}, fmt.Errorf("llm status %d: %s", resp.StatusCode, msg)
	}
	if len(parsed.Choices) == 0 || strings.TrimSpace(parsed.Choices[0].Message.Content) == "" {
		return Result{}, ErrEmptyResponse
	}
	return Result{
		Content:          strings.TrimSpace(parsed.Choices[0].Message.Content),
		Model:            parsed.Model,
		PromptTokens:     parsed.Usage.PromptTokens,
		CompletionTokens: parsed.Usage.CompletionTokens,
	}, nil
}
