package embed

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func vec(v float32) []float32 {
	out := make([]float32, Dimensions)
	out[0] = v
	return out
}

func TestEmbed_BatchesAndKeepsOrder(t *testing.T) {
	// Arrange: the server answers each batch in reverse index order.
	var batches []int
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var req request
		_ = json.NewDecoder(r.Body).Decode(&req)
		if r.URL.Path != "/embeddings" || r.Header.Get("Authorization") != "Bearer k" || req.Dimensions != Dimensions || req.Model != "m" {
			t.Errorf("bad request path=%s auth=%q req=%+v", r.URL.Path, r.Header.Get("Authorization"), req)
		}
		batches = append(batches, len(req.Input))
		type item struct {
			Index     int       `json:"index"`
			Embedding []float32 `json:"embedding"`
		}
		var data []item
		for i := len(req.Input) - 1; i >= 0; i-- {
			var n float32
			for _, c := range req.Input[i] {
				n = float32(c - '0')
			}
			data = append(data, item{i, vec(n)})
		}
		_ = json.NewEncoder(w).Encode(map[string]any{"data": data})
	}))
	defer srv.Close()
	texts := make([]string, batchSize+2)
	for i := range texts {
		texts[i] = string(rune('0' + i%10))
	}

	// Act
	got, err := New(srv.URL, "k", "m", nil).Embed(context.Background(), texts)

	// Assert
	if err != nil {
		t.Fatal(err)
	}
	if len(batches) != 2 || batches[0] != batchSize || batches[1] != 2 {
		t.Errorf("batches = %v", batches)
	}
	for i, v := range got {
		if v[0] != float32(i%10) {
			t.Fatalf("vector %d out of order: %v", i, v[0])
		}
	}
}

func TestEmbed_RejectsWrongDimensionsAndErrors(t *testing.T) {
	cases := map[string]struct {
		status int
		body   string
		want   string
	}{
		"wrong dimensions": {200, `{"data":[{"index":0,"embedding":[0.1,0.2]}]}`, "returned 2 dimensions"},
		"api error":        {401, `{"error":{"message":"Incorrect API key"}}`, "status 401: Incorrect API key"},
		"missing vectors":  {200, `{"data":[]}`, "got 0 vectors"},
	}
	for name, tc := range cases {
		t.Run(name, func(t *testing.T) {
			// Arrange
			srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
				w.WriteHeader(tc.status)
				_, _ = w.Write([]byte(tc.body))
			}))
			defer srv.Close()

			// Act
			_, err := New(srv.URL, "k", "m", nil).Embed(context.Background(), []string{"x"})

			// Assert
			if err == nil || !strings.Contains(err.Error(), tc.want) {
				t.Errorf("err = %v, want %q", err, tc.want)
			}
		})
	}
}

func TestSwitch_NotConfiguredThenSet(t *testing.T) {
	// Arrange
	s := &Switch{}

	// Act
	_, errBefore := s.Embed(context.Background(), []string{"x"})
	modelBefore := s.Model()
	s.Set(New("http://x", "k", "m1", nil))

	// Assert
	if !errors.Is(errBefore, ErrNotConfigured) || modelBefore != "" {
		t.Errorf("before: err=%v model=%q", errBefore, modelBefore)
	}
	if s.Model() != "m1" {
		t.Errorf("after: model=%q", s.Model())
	}
}
