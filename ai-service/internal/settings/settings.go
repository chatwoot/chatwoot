// Package settings persists the AI provider settings (chat models and the
// embeddings model) an admin edits on the settings page. Environment variables give the initial values; once saved,
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

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/config"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/embed"
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
	} else if u.User != nil {
		// Credentials belong in the API key field, never in a URL that gets logged.
		errs = append(errs, errors.New("base URL must not contain a username or password"))
	}
	if p.APIKey == "" {
		errs = append(errs, errors.New("API key is required"))
	}
	if p.Model == "" {
		errs = append(errs, errors.New("model is required"))
	}
	return errors.Join(errs...)
}

// LLM holds the primary chat provider, an optional fallback, and the
// optional embeddings provider used by the knowledge base.
type LLM struct {
	Primary   Provider `json:"primary"`
	Fallback  Provider `json:"fallback"`
	Embedding Provider `json:"embedding"`
}

// Normalize trims whitespace and the trailing slash of the base URL.
func (p Provider) Normalize() Provider {
	return Provider{
		BaseURL: strings.TrimRight(strings.TrimSpace(p.BaseURL), "/"),
		APIKey:  strings.TrimSpace(p.APIKey),
		Model:   strings.TrimSpace(p.Model),
	}
}

// Host returns only the host of the base URL, safe to log.
func (p Provider) Host() string {
	u, err := url.Parse(p.BaseURL)
	if err != nil {
		return ""
	}
	return u.Host
}

// Normalize trims every provider.
func (s LLM) Normalize() LLM {
	return LLM{Primary: s.Primary.Normalize(), Fallback: s.Fallback.Normalize(), Embedding: s.Embedding.Normalize()}
}

// Validate checks every provider. The primary must be complete.
func (s LLM) Validate() error {
	var errs []error
	if s.Primary == (Provider{}) {
		errs = append(errs, errors.New("Primary provider: base URL, API key and model are required"))
	} else {
		errs = append(errs, prefixEach("Primary provider", s.Primary.Validate())...)
	}
	errs = append(errs, prefixEach("Fallback provider", s.Fallback.Validate())...)
	errs = append(errs, prefixEach("Embeddings provider", s.Embedding.Validate())...)
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
	var saved struct {
		LLM
		Embedding *Provider `json:"embedding"`
	}
	if err := json.Unmarshal(raw, &saved); err != nil {
		return nil, fmt.Errorf("parse settings %s: %w", path, err)
	}
	// Files saved before the embeddings provider existed have no "embedding"
	// key; keep the env default for it instead of turning it off.
	saved.LLM.Embedding = defaults.Embedding
	if saved.Embedding != nil {
		saved.LLM.Embedding = *saved.Embedding
	}
	s.current = saved.LLM.Normalize()
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

// Defaults builds the initial settings from environment configuration.
func Defaults(cfg config.Config) LLM {
	return LLM{
		Primary:   Provider{BaseURL: cfg.LLMBaseURL, APIKey: cfg.LLMAPIKey, Model: cfg.LLMModel},
		Fallback:  Provider{BaseURL: cfg.LLMFallbackBaseURL, APIKey: cfg.LLMFallbackAPIKey, Model: cfg.LLMFallbackModel},
		Embedding: Provider{BaseURL: cfg.EmbedBaseURL, APIKey: cfg.EmbedAPIKey, Model: cfg.EmbedModel},
	}
}

// NewEmbedder builds the embeddings client, or nil when none is configured.
func NewEmbedder(s LLM, timeout time.Duration) embed.Embedder {
	if !s.Embedding.Configured() {
		return nil
	}
	p := s.Embedding
	return embed.New(p.BaseURL, p.APIKey, p.Model, &http.Client{Timeout: timeout})
}

func newClient(p Provider, timeout time.Duration) *llm.Client {
	return llm.New(p.BaseURL, p.APIKey, p.Model, &http.Client{Timeout: timeout})
}
