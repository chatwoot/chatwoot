// Package embed turns text into vectors through an OpenAI-compatible
// embeddings API (POST {base}/embeddings).
package embed

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"sync/atomic"
)

// Dimensions is the vector size stored in the knowledge base. Models that
// accept the "dimensions" parameter (OpenAI text-embedding-3-*) return it.
const Dimensions = 1536

// batchSize keeps each request well under provider input limits.
const batchSize = 64

// Embedder turns texts into vectors, one per input, in order.
type Embedder interface {
	Embed(ctx context.Context, texts []string) ([][]float32, error)
	// Model names the embedding model; vectors from different models are not comparable.
	Model() string
}

// ErrNotConfigured means no embeddings provider is set.
var ErrNotConfigured = errors.New("embeddings provider not configured")

// Client talks to one OpenAI-compatible embeddings endpoint.
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

// Model implements Embedder.
func (c *Client) Model() string { return c.model }

type request struct {
	Model      string   `json:"model"`
	Input      []string `json:"input"`
	Dimensions int      `json:"dimensions"`
}

type response struct {
	Data []struct {
		Index     int       `json:"index"`
		Embedding []float32 `json:"embedding"`
	} `json:"data"`
	Error *struct {
		Message string `json:"message"`
	} `json:"error"`
}

// Embed implements Embedder. Inputs are sent in batches.
func (c *Client) Embed(ctx context.Context, texts []string) ([][]float32, error) {
	out := make([][]float32, 0, len(texts))
	for start := 0; start < len(texts); start += batchSize {
		end := min(start+batchSize, len(texts))
		vecs, err := c.embedBatch(ctx, texts[start:end])
		if err != nil {
			return nil, err
		}
		out = append(out, vecs...)
	}
	return out, nil
}

func (c *Client) embedBatch(ctx context.Context, texts []string) ([][]float32, error) {
	buf, err := json.Marshal(request{Model: c.model, Input: texts, Dimensions: Dimensions})
	if err != nil {
		return nil, err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+"/embeddings", bytes.NewReader(buf))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+c.apiKey)

	resp, err := c.http.Do(req)
	if err != nil {
		return nil, fmt.Errorf("embeddings request: %w", err)
	}
	defer resp.Body.Close()
	raw, err := io.ReadAll(io.LimitReader(resp.Body, 64<<20))
	if err != nil {
		return nil, fmt.Errorf("embeddings read: %w", err)
	}
	var parsed response
	if err := json.Unmarshal(raw, &parsed); err != nil {
		return nil, fmt.Errorf("embeddings status %d: invalid json", resp.StatusCode)
	}
	if resp.StatusCode/100 != 2 || parsed.Error != nil {
		msg := ""
		if parsed.Error != nil {
			msg = parsed.Error.Message
		}
		return nil, fmt.Errorf("embeddings status %d: %s", resp.StatusCode, msg)
	}
	if len(parsed.Data) != len(texts) {
		return nil, fmt.Errorf("embeddings: got %d vectors for %d inputs", len(parsed.Data), len(texts))
	}
	out := make([][]float32, len(texts))
	for _, d := range parsed.Data {
		if d.Index < 0 || d.Index >= len(texts) || out[d.Index] != nil {
			return nil, fmt.Errorf("embeddings: bad index %d", d.Index)
		}
		if len(d.Embedding) != Dimensions {
			return nil, fmt.Errorf("embeddings: model returned %d dimensions, need %d (use a model that supports the dimensions parameter, e.g. text-embedding-3-small)", len(d.Embedding), Dimensions)
		}
		out[d.Index] = d.Embedding
	}
	return out, nil
}

// Switch is an Embedder whose target can be replaced at runtime, like llm.Switch.
type Switch struct {
	current atomic.Pointer[box]
}

type box struct{ e Embedder }

// Set replaces the target; nil means "not configured".
func (s *Switch) Set(e Embedder) { s.current.Store(&box{e}) }

func (s *Switch) get() Embedder {
	if b := s.current.Load(); b != nil {
		return b.e
	}
	return nil
}

// Embed implements Embedder.
func (s *Switch) Embed(ctx context.Context, texts []string) ([][]float32, error) {
	e := s.get()
	if e == nil {
		return nil, ErrNotConfigured
	}
	return e.Embed(ctx, texts)
}

// Model implements Embedder; empty when not configured.
func (s *Switch) Model() string {
	if e := s.get(); e != nil {
		return e.Model()
	}
	return ""
}
