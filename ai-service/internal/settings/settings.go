// Package settings persists the LLM provider settings an admin edits on the
// settings page. Environment variables give the initial values; once saved,
// the file wins.
package settings

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/fs"
	"log/slog"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/llm"
)

// Provider is one OpenAI-compatible endpoint.
type Provider struct {
	BaseURL string `json:"base_url"`
	APIKey  string `json:"api_key"`
	Model   string `json:"model"`
}

// Configured reports whether every field is set.
func (p Provider) Configured() bool {
	return p.BaseURL != "" && p.APIKey != "" && p.Model != ""
}

// Validate checks a provider the admin wants to save. An empty provider is
// valid (means "not used"); a partly filled one is not.
func (p Provider) Validate() error {
	if p == (Provider{}) {
		return nil
	}
	var errs []error
	u, err := url.Parse(p.BaseURL)
	if p.BaseURL == "" || err != nil || (u.Scheme != "https" && u.Scheme != "http") || u.Host == "" {
		errs = append(errs, errors.New("base URL must be an http(s) URL"))
	}
	if p.APIKey == "" {
		errs = append(errs, errors.New("API key is required"))
	}
	if p.Model == "" {
		errs = append(errs, errors.New("model is required"))
	}
	return errors.Join(errs...)
}

// LLM holds the primary provider and an optional fallback.
type LLM struct {
	Primary  Provider `json:"primary"`
	Fallback Provider `json:"fallback"`
}

// Normalize trims whitespace and trailing slashes.
func (s LLM) Normalize() LLM {
	clean := func(p Provider) Provider {
		return Provider{
			BaseURL: strings.TrimRight(strings.TrimSpace(p.BaseURL), "/"),
			APIKey:  strings.TrimSpace(p.APIKey),
			Model:   strings.TrimSpace(p.Model),
		}
	}
	return LLM{Primary: clean(s.Primary), Fallback: clean(s.Fallback)}
}

// Validate checks both providers. The primary must be complete.
func (s LLM) Validate() error {
	var errs []error
	if s.Primary == (Provider{}) {
		errs = append(errs, errors.New("Primary provider: base URL, API key and model are required"))
	} else {
		errs = append(errs, prefixEach("Primary provider", s.Primary.Validate())...)
	}
	errs = append(errs, prefixEach("Fallback provider", s.Fallback.Validate())...)
	return errors.Join(errs...)
}

// prefixEach labels every line of a joined error so each reads on its own.
func prefixEach(label string, err error) []error {
	if err == nil {
		return nil
	}
	var out []error
	for _, line := range strings.Split(err.Error(), "\n") {
		out = append(out, fmt.Errorf("%s: %s", label, line))
	}
	return out
}

// Store keeps the current settings in memory and on disk.
type Store struct {
	mu      sync.Mutex
	path    string
	current LLM
}

// Open loads settings from path, or uses defaults when the file does not exist.
func Open(path string, defaults LLM) (*Store, error) {
	s := &Store{path: path, current: defaults.Normalize()}
	raw, err := os.ReadFile(path)
	if errors.Is(err, fs.ErrNotExist) {
		return s, nil
	}
	if err != nil {
		return nil, fmt.Errorf("read settings: %w", err)
	}
	var saved LLM
	if err := json.Unmarshal(raw, &saved); err != nil {
		return nil, fmt.Errorf("parse settings %s: %w", path, err)
	}
	s.current = saved.Normalize()
	return s, nil
}

// Get returns the current settings.
func (s *Store) Get() LLM {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.current
}

// Save validates, writes atomically (0600) and makes the settings current.
func (s *Store) Save(next LLM) error {
	next = next.Normalize()
	if err := next.Validate(); err != nil {
		return err
	}
	buf, err := json.MarshalIndent(next, "", "  ")
	if err != nil {
		return err
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if err := os.MkdirAll(filepath.Dir(s.path), 0o700); err != nil {
		return fmt.Errorf("create settings dir: %w", err)
	}
	tmp, err := os.CreateTemp(filepath.Dir(s.path), ".settings-*.json")
	if err != nil {
		return fmt.Errorf("write settings: %w", err)
	}
	defer os.Remove(tmp.Name()) // no-op after a successful rename
	if err := tmp.Chmod(0o600); err != nil {
		tmp.Close()
		return err
	}
	if _, err := tmp.Write(buf); err != nil {
		tmp.Close()
		return err
	}
	if err := tmp.Close(); err != nil {
		return err
	}
	if err := os.Rename(tmp.Name(), s.path); err != nil {
		return fmt.Errorf("write settings: %w", err)
	}
	s.current = next
	return nil
}

// Mask shows only the last 4 characters of a secret.
func Mask(secret string) string {
	if secret == "" {
		return ""
	}
	r := []rune(secret)
	if len(r) <= 8 {
		return "••••"
	}
	return "••••" + string(r[len(r)-4:])
}

// NewCompleter builds the LLM chain (primary, then fallback if configured).
// Each provider call is bounded by timeout.
func NewCompleter(s LLM, timeout time.Duration, logger *slog.Logger) llm.Completer {
	if !s.Primary.Configured() {
		return nil
	}
	f := &llm.Fallback{Primary: newClient(s.Primary, timeout), Logger: logger}
	if s.Fallback.Configured() {
		f.Secondary = newClient(s.Fallback, timeout)
	}
	return f
}

func newClient(p Provider, timeout time.Duration) *llm.Client {
	return llm.New(p.BaseURL, p.APIKey, p.Model, &http.Client{Timeout: timeout})
}
