// Package media downloads customer attachments from Chatwoot and transcribes
// voice notes. Downloads are locked to the Chatwoot host (including every
// redirect) so a webhook can never make ai-service fetch another address.
package media

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"net/url"
	"strings"
	"time"
)

// Fetcher downloads attachment files.
type Fetcher struct {
	Host      string // Chatwoot host, e.g. chat.example.com; nothing else is fetched
	MaxBytes  int64
	AllowHTTP bool // tests only; production requires https
	Client    *http.Client
}

// Fetch returns the file and its content type.
func (f *Fetcher) Fetch(ctx context.Context, raw string) ([]byte, string, error) {
	if err := f.allowed(raw); err != nil {
		return nil, "", err
	}
	client := f.client()
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, raw, nil)
	if err != nil {
		return nil, "", errors.New("bad attachment url")
	}
	res, err := client.Do(req)
	if err != nil {
		return nil, "", errors.New("attachment download failed")
	}
	defer res.Body.Close()
	if res.StatusCode != http.StatusOK {
		return nil, "", fmt.Errorf("attachment download status %d", res.StatusCode)
	}
	body, err := io.ReadAll(io.LimitReader(res.Body, f.MaxBytes+1))
	if err != nil {
		return nil, "", errors.New("attachment read failed")
	}
	if int64(len(body)) > f.MaxBytes {
		return nil, "", fmt.Errorf("attachment over %d bytes", f.MaxBytes)
	}
	return body, res.Header.Get("Content-Type"), nil
}

func (f *Fetcher) allowed(raw string) error {
	u, err := url.Parse(raw)
	if err != nil || u.Host == "" {
		return errors.New("bad attachment url")
	}
	if u.Scheme != "https" && !(f.AllowHTTP && u.Scheme == "http") {
		return errors.New("attachment url must be https")
	}
	if !strings.EqualFold(u.Host, f.Host) {
		return errors.New("attachment is not on the Chatwoot host")
	}
	return nil
}

func (f *Fetcher) client() *http.Client {
	base := f.Client
	if base == nil {
		base = &http.Client{Timeout: 20 * time.Second}
	}
	c := *base
	c.CheckRedirect = func(req *http.Request, via []*http.Request) error {
		if len(via) >= 5 {
			return errors.New("too many redirects")
		}
		return f.allowed(req.URL.String())
	}
	return &c
}

// Transcriber turns a voice note into text with an OpenAI-compatible
// /audio/transcriptions endpoint.
type Transcriber struct {
	BaseURL, APIKey, Model string
	Client                 *http.Client
}

// Transcribe returns the spoken text.
func (t *Transcriber) Transcribe(ctx context.Context, audio []byte, filename string) (string, error) {
	var body bytes.Buffer
	w := multipart.NewWriter(&body)
	_ = w.WriteField("model", t.Model)
	part, err := w.CreateFormFile("file", filename)
	if err != nil {
		return "", err
	}
	if _, err := part.Write(audio); err != nil {
		return "", err
	}
	if err := w.Close(); err != nil {
		return "", err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, strings.TrimRight(t.BaseURL, "/")+"/audio/transcriptions", &body)
	if err != nil {
		return "", errors.New("transcription request failed")
	}
	req.Header.Set("Authorization", "Bearer "+t.APIKey)
	req.Header.Set("Content-Type", w.FormDataContentType())
	client := t.Client
	if client == nil {
		client = &http.Client{Timeout: 60 * time.Second}
	}
	res, err := client.Do(req)
	if err != nil {
		return "", errors.New("transcription call failed") // the raw error carries the URL
	}
	defer res.Body.Close()
	var out struct {
		Text  string `json:"text"`
		Error struct {
			Message string `json:"message"`
		} `json:"error"`
	}
	if err := json.NewDecoder(io.LimitReader(res.Body, 1<<20)).Decode(&out); err != nil {
		return "", fmt.Errorf("transcription response status %d", res.StatusCode)
	}
	if res.StatusCode != http.StatusOK {
		return "", fmt.Errorf("transcription status %d", res.StatusCode)
	}
	return strings.TrimSpace(out.Text), nil
}
