package config

import (
	"strings"
	"testing"
	"time"
)

func lookupFrom(m map[string]string) func(string) (string, bool) {
	return func(k string) (string, bool) { v, ok := m[k]; return v, ok }
}

func requiredEnv() map[string]string {
	return map[string]string{
		"CHATWOOT_BASE_URL":       "http://rails:3000/",
		"CHATWOOT_BOT_TOKEN":      "tok",
		"CHATWOOT_WEBHOOK_SECRET": "sec",
		"LLM_API_KEY":             "key",
		"LLM_MODEL":               "some/model",
	}
}

func TestLoad_AppliesDefaults(t *testing.T) {
	// Arrange
	env := requiredEnv()

	// Act
	cfg, err := Load(lookupFrom(env))

	// Assert
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cfg.ChatwootBaseURL != "http://rails:3000" {
		t.Errorf("trailing slash not trimmed: %q", cfg.ChatwootBaseURL)
	}
	if cfg.LLMBaseURL != "https://openrouter.ai/api/v1" || cfg.LLMTimeout != 45*time.Second {
		t.Errorf("bad LLM defaults: %q %v", cfg.LLMBaseURL, cfg.LLMTimeout)
	}
	if cfg.Workers != 4 || cfg.QueueSize != 256 || cfg.HistoryLimit != 20 {
		t.Errorf("bad numeric defaults: %+v", cfg)
	}
	if len(cfg.HandoffKeywords) == 0 {
		t.Error("expected default handoff keywords")
	}
}

func TestLoad_ReportsAllMissingRequired(t *testing.T) {
	// Arrange
	env := map[string]string{}

	// Act
	_, err := Load(lookupFrom(env))

	// Assert
	if err == nil {
		t.Fatal("expected error")
	}
	for _, key := range []string{"CHATWOOT_BASE_URL", "CHATWOOT_BOT_TOKEN", "CHATWOOT_WEBHOOK_SECRET", "LLM_API_KEY", "LLM_MODEL"} {
		if !strings.Contains(err.Error(), key) {
			t.Errorf("error does not mention %s: %v", key, err)
		}
	}
}

func TestLoad_ParsesOverrides(t *testing.T) {
	// Arrange
	env := requiredEnv()
	env["HANDOFF_KEYWORDS"] = " refund , , complaint "
	env["WORKERS"] = "2"

	// Act
	cfg, err := Load(lookupFrom(env))

	// Assert
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if strings.Join(cfg.HandoffKeywords, "|") != "refund|complaint" {
		t.Errorf("keywords = %v", cfg.HandoffKeywords)
	}
	if cfg.Workers != 2 {
		t.Errorf("workers = %d", cfg.Workers)
	}
}

func TestLoad_RejectsBadNumbers(t *testing.T) {
	// Arrange
	env := requiredEnv()
	env["QUEUE_SIZE"] = "0"
	env["LLM_TIMEOUT"] = "soon"

	// Act
	_, err := Load(lookupFrom(env))

	// Assert
	if err == nil || !strings.Contains(err.Error(), "QUEUE_SIZE") || !strings.Contains(err.Error(), "LLM_TIMEOUT") {
		t.Fatalf("expected QUEUE_SIZE and LLM_TIMEOUT errors, got %v", err)
	}
}
