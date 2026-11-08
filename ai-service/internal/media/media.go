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
	Host string // Chatwoot host, e.g. chat.example.com; nothing else is fetched
	// PublicHost is the host Chatwoot writes into attachment links when it
	// differs from Host (local Docker: links say localhost:3000, the bot
	// reaches Chatwoot as rails:3000). Such links are fetched from Host.
	PublicHost string
	// HostScheme is the scheme for links moved to Host ("http" inside
	// Docker); empty keeps the link's own scheme.
	HostScheme string
	MaxBytes   int64
	// RetryWait is the first pause before asking again for a file that
	// answered 404: Chatwoot sends the webhook before the upload finishes.
	// It doubles each time (3 retries). Zero means 500ms.
	RetryWait time.Duration
	AllowHTTP bool // tests, and Docker service names (rails:3000); public hosts need https
	Client    *http.Client
}

// Fetch returns the file and its content type. max (if smaller) tightens
// MaxBytes for this call, so an image stops at its own limit while reading.
func (f *Fetcher) Fetch(ctx context.Context, raw string, max int64) ([]byte, string, error) {
	limit := f.MaxBytes
	if max > 0 && max < limit {
		limit = max
	}
	if err := f.allowed(raw); err != nil {
		return nil, "", err
	}
	res, err := f.get(ctx, f.internal(raw))
	if err != nil {
		return nil, "", err
	}
	defer res.Body.Close()
	if res.StatusCode != http.StatusOK {
		return nil, "", fmt.Errorf("attachment download status %d", res.StatusCode)
	}
	body, err := io.ReadAll(io.LimitReader(res.Body, limit+1))
	if err != nil {
		return nil, "", errors.New("attachment read failed")
	}
	if int64(len(body)) > limit {
		return nil, "", fmt.Errorf("attachment over %d bytes", limit)
	}
	return body, res.Header.Get("Content-Type"), nil
}

// get requests the file, asking again while it answers 404 (still uploading).
func (f *Fetcher) get(ctx context.Context, link string) (*http.Response, error) {
	client := f.client()
	wait := f.RetryWait
	if wait <= 0 {
		wait = 500 * time.Millisecond
	}
	for try := 0; ; try++ {
		req, err := http.NewRequestWithContext(ctx, http.MethodGet, link, nil)
		if err != nil {
			return nil, errors.New("bad attachment url")
		}
		res, err := client.Do(req)
		if err != nil {
			return nil, errors.New("attachment download failed")
		}
		if res.StatusCode != http.StatusNotFound || try == 3 {
			return res, nil
		}
		res.Body.Close()
		select {
		case <-ctx.Done():
			return nil, errors.New("attachment download failed")
		case <-time.After(wait):
		}
		wait *= 2
	}
}

func (f *Fetcher) allowed(raw string) error {
	u, err := url.Parse(raw)
	if err != nil || u.Host == "" || f.Host == "" || u.User != nil {
		return errors.New("bad attachment url")
	}
	if u.Scheme != "https" && !(f.AllowHTTP && u.Scheme == "http") {
		return errors.New("attachment url must be https")
	}
	if !strings.EqualFold(u.Host, f.Host) && (f.PublicHost == "" || !strings.EqualFold(u.Host, f.PublicHost)) {
		return errors.New("attachment is not on the Chatwoot host")
	}
	return nil
}

// internal points a link on PublicHost at Host; any other link is unchanged.
// Call it only after allowed.
func (f *Fetcher) internal(raw string) string {
	u, err := url.Parse(raw)
	if err != nil || f.PublicHost == "" || !strings.EqualFold(u.Host, f.PublicHost) {
		return raw
	}
	u.Host = f.Host
	if f.HostScheme != "" {
		u.Scheme = f.HostScheme
	}
	return u.String()
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
		if err := f.allowed(req.URL.String()); err != nil {
			return err
		}
		if f.PublicHost != "" && strings.EqualFold(req.URL.Host, f.PublicHost) {
			req.URL.Host = f.Host
			req.Host = f.Host
			if f.HostScheme != "" {
				req.URL.Scheme = f.HostScheme
			}
		}
		return nil
	}
	return &c
}

// Transcriber turns a voice note into text with an OpenAI-compatible
// /audio/transcriptions endpoint.
type Transcriber struct {
	BaseURL, APIKey, Model string
	// Prompt lists words the speaker may use (business and product names),
	// which the model then spells correctly. Optional.
	Prompt string
	Client *http.Client
}

// Transcribe returns the spoken text.
func (t *Transcriber) Transcribe(ctx context.Context, audio []byte, filename string) (string, error) {
	var body bytes.Buffer
	w := multipart.NewWriter(&body)
	_ = w.WriteField("model", t.Model)
	if t.Prompt != "" {
		_ = w.WriteField("prompt", t.Prompt)
	}
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
