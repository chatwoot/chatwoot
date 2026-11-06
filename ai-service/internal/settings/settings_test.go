package settings

import (
	"context"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/llm"
)

func good() Provider {
	return Provider{BaseURL: "https://api.openai.com/v1/", APIKey: " sk-test-1234 ", Model: "m"}
}

func TestOpen_UsesDefaultsWhenNoFile(t *testing.T) {
	// Arrange
	path := filepath.Join(t.TempDir(), "settings.json")

	// Act
	s, err := Open(path, LLM{Primary: good()})

	// Assert
	if err != nil {
		t.Fatalf("open: %v", err)
	}
	if got := s.Get().Primary; got.BaseURL != "https://api.openai.com/v1" || got.APIKey != "sk-test-1234" {
		t.Errorf("defaults not normalized: %+v", got)
	}
}

func TestSave_PersistsWith0600AndWinsOverDefaults(t *testing.T) {
	// Arrange
	path := filepath.Join(t.TempDir(), "sub", "settings.json")
	s, _ := Open(path, LLM{})
	saved := LLM{Primary: good(), Fallback: Provider{BaseURL: "https://openrouter.ai/api/v1", APIKey: "k2", Model: "m2"}}

	// Act
	err := s.Save(saved)
	reopened, openErr := Open(path, LLM{Primary: Provider{BaseURL: "https://other", APIKey: "x", Model: "y"}})

	// Assert
	if err != nil || openErr != nil {
		t.Fatalf("save=%v open=%v", err, openErr)
	}
	info, _ := os.Stat(path)
	if info.Mode().Perm() != 0o600 {
		t.Errorf("perm = %v, want 0600", info.Mode().Perm())
	}
	if got := reopened.Get(); got.Fallback.Model != "m2" || got.Primary.Model != "m" {
		t.Errorf("reopened = %+v", got)
	}
}

func TestSave_RejectsInvalidAndKeepsCurrent(t *testing.T) {
	cases := []struct {
		name string
		in   LLM
		want string
	}{
		{"empty primary", LLM{}, "Primary provider"},
		{"bad url", LLM{Primary: Provider{BaseURL: "ftp://x", APIKey: "k", Model: "m"}}, "base URL"},
		{"partial fallback", LLM{Primary: good(), Fallback: Provider{BaseURL: "https://x"}}, "Fallback provider: model is required"},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			// Arrange
			s, _ := Open(filepath.Join(t.TempDir(), "s.json"), LLM{Primary: good()})

			// Act
			err := s.Save(tc.in)

			// Assert
			if err == nil || !strings.Contains(err.Error(), tc.want) {
				t.Errorf("err = %v, want mention of %q", err, tc.want)
			}
			if s.Get().Primary.Model != "m" {
				t.Error("invalid save changed current settings")
			}
		})
	}
}

func TestOpen_CorruptFileIsAnError(t *testing.T) {
	// Arrange
	path := filepath.Join(t.TempDir(), "s.json")
	_ = os.WriteFile(path, []byte("{nope"), 0o600)

	// Act
	_, err := Open(path, LLM{})

	// Assert
	if err == nil {
		t.Error("expected parse error")
	}
}

func TestMask(t *testing.T) {
	cases := map[string]string{"": "", "short": "••••", "sk-or-v1-abcdef123456": "••••3456"}
	for in, want := range cases {
		// Arrange: table

		// Act
		got := Mask(in)

		// Assert
		if got != want {
			t.Errorf("Mask(%q) = %q, want %q", in, got, want)
		}
	}
}

func TestNewCompleter_FallsBackToSecondProvider(t *testing.T) {
	// Arrange: primary returns 500, fallback answers.
	down := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(500)
		_, _ = w.Write([]byte(`{"error":{"message":"down"}}`))
	}))
	defer down.Close()
	up := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		_, _ = w.Write([]byte(`{"model":"fb","choices":[{"message":{"content":"from fallback"}}]}`))
	}))
	defer up.Close()
	c := NewCompleter(LLM{
		Primary:  Provider{BaseURL: down.URL, APIKey: "a", Model: "p"},
		Fallback: Provider{BaseURL: up.URL, APIKey: "b", Model: "fb"},
	}, 5*time.Second, nil)

	// Act
	res, err := c.Complete(context.Background(), []llm.Message{{Role: "user", Content: "hi"}})

	// Assert
	if err != nil || res.Content != "from fallback" || !res.UsedFallback {
		t.Errorf("res=%+v err=%v", res, err)
	}
}

func TestNewCompleter_NilWhenPrimaryMissing(t *testing.T) {
	// Arrange
	s := LLM{}

	// Act
	c := NewCompleter(s, time.Second, nil)

	// Assert
	if c != nil {
		t.Error("expected nil completer")
	}
}

func TestValidate_RejectsCredentialsInURL(t *testing.T) {
	// Arrange
	p := Provider{BaseURL: "https://user:pass@api.example.com/v1", APIKey: "k", Model: "m"}

	// Act
	err := p.Validate()

	// Assert
	if err == nil || !strings.Contains(err.Error(), "username or password") {
		t.Errorf("err = %v", err)
	}
}

func TestHost_ReturnsHostOnly(t *testing.T) {
	// Arrange
	p := Provider{BaseURL: "https://api.openai.com/v1?x=secret"}

	// Act
	host := p.Host()

	// Assert
	if host != "api.openai.com" {
		t.Errorf("host = %q", host)
	}
}

func TestOpen_OldFileKeepsEnvEmbeddingDefault(t *testing.T) {
	// Arrange: a settings file saved before "embedding" existed.
	path := filepath.Join(t.TempDir(), "s.json")
	old := `{"primary":{"base_url":"https://api.openai.com/v1","api_key":"sk-1","model":"m"},"fallback":{"base_url":"","api_key":"","model":""}}`
	if err := os.WriteFile(path, []byte(old), 0o600); err != nil {
		t.Fatal(err)
	}
	def := LLM{Embedding: Provider{BaseURL: "https://api.openai.com/v1", APIKey: "sk-e", Model: "text-embedding-3-small"}}

	// Act
	s, err := Open(path, def)

	// Assert
	if err != nil || s.Get().Embedding != def.Embedding || s.Get().Primary.APIKey != "sk-1" {
		t.Errorf("got %+v err=%v", s.Get(), err)
	}
}

func TestOpen_SavedEmptyEmbeddingStaysOff(t *testing.T) {
	// Arrange: the admin turned embeddings off; the env default must not come back.
	path := filepath.Join(t.TempDir(), "s.json")
	saved := `{"primary":{"base_url":"https://a","api_key":"k","model":"m"},"embedding":{"base_url":"","api_key":"","model":""}}`
	if err := os.WriteFile(path, []byte(saved), 0o600); err != nil {
		t.Fatal(err)
	}

	// Act
	s, err := Open(path, LLM{Embedding: Provider{BaseURL: "https://e", APIKey: "k", Model: "e"}})

	// Assert
	if err != nil || s.Get().Embedding != (Provider{}) {
		t.Errorf("embedding = %+v err=%v", s.Get().Embedding, err)
	}
}

func TestValidate_LabelsEmbeddingErrors(t *testing.T) {
	// Arrange
	s := LLM{
		Primary:   Provider{BaseURL: "https://a", APIKey: "k", Model: "m"},
		Embedding: Provider{BaseURL: "https://a", Model: "e"},
	}

	// Act
	err := s.Validate()

	// Assert
	if err == nil || err.Error() != "Embeddings provider: API key is required" {
		t.Errorf("err = %v", err)
	}
}

func TestRewriteSettings(t *testing.T) {
	// Arrange
	main := LLM{
		Primary:  Provider{BaseURL: "https://api.openai.com/v1", APIKey: "k1", Model: "gpt-6-luna"},
		Fallback: Provider{BaseURL: "https://openrouter.ai/api/v1", APIKey: "k2", Model: "other"},
	}

	// Act
	same := RewriteSettings(main, "")
	fast := RewriteSettings(main, "gpt-5.4-mini")

	// Assert
	if same != main {
		t.Errorf("no rewrite model must keep the main settings, got %+v", same)
	}
	if fast.Primary.Model != "gpt-5.4-mini" || fast.Primary.BaseURL != main.Primary.BaseURL || fast.Primary.APIKey != "k1" {
		t.Errorf("fast primary = %+v, want the main provider with the small model", fast.Primary)
	}
	if fast.Fallback != main.Primary {
		t.Errorf("fast fallback = %+v, want the main model, so a bad small model still rewrites", fast.Fallback)
	}
}
