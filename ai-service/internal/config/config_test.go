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
	for _, key := range []string{"CHATWOOT_BASE_URL", "CHATWOOT_BOT_TOKEN", "CHATWOOT_WEBHOOK_SECRET"} {
		if !strings.Contains(err.Error(), key) {
			t.Errorf("error does not mention %s: %v", key, err)
		}
	}
	// LLM settings are optional at startup: the admin page can set them.
	if strings.Contains(err.Error(), "LLM_") {
		t.Errorf("LLM settings must not be required: %v", err)
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

func TestLoad_FallbackAndAdminSettings(t *testing.T) {
	// Arrange
	env := requiredEnv()
	env["LLM_FALLBACK_BASE_URL"] = "https://api.openai.com/v1/"
	env["LLM_FALLBACK_API_KEY"] = "fk"
	env["LLM_FALLBACK_MODEL"] = "fm"
	env["ADMIN_PASSWORD"] = "a-long-enough-password"

	// Act
	cfg, err := Load(lookupFrom(env))

	// Assert
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cfg.LLMFallbackBaseURL != "https://api.openai.com/v1" || cfg.LLMFallbackAPIKey != "fk" || cfg.LLMFallbackModel != "fm" {
		t.Errorf("fallback = %q %q %q", cfg.LLMFallbackBaseURL, cfg.LLMFallbackAPIKey, cfg.LLMFallbackModel)
	}
	if cfg.SettingsPath != "/data/settings.json" {
		t.Errorf("settings path = %q", cfg.SettingsPath)
	}
}

func TestLoad_RejectsShortAdminPassword(t *testing.T) {
	// Arrange
	env := requiredEnv()
	env["ADMIN_PASSWORD"] = "short"

	// Act
	_, err := Load(lookupFrom(env))

	// Assert
	if err == nil || !strings.Contains(err.Error(), "ADMIN_PASSWORD") {
		t.Fatalf("err = %v", err)
	}
}

func TestLoad_RAGDefaultsAndValidation(t *testing.T) {
	// Arrange
	base := map[string]string{"CHATWOOT_BASE_URL": "http://x", "CHATWOOT_BOT_TOKEN": "t", "CHATWOOT_WEBHOOK_SECRET": "s"}
	bad := map[string]string{"RAG_MIN_SCORE": "high", "RAG_TOP_K": "0"}
	for k, v := range base {
		bad[k] = v
	}
	lookup := func(m map[string]string) func(string) (string, bool) {
		return func(k string) (string, bool) { v, ok := m[k]; return v, ok }
	}

	// Act
	cfg, err := Load(lookup(base))
	_, badErr := Load(lookup(bad))

	// Assert
	if err != nil || cfg.DatabaseURL != "" || cfg.RAGTopK != 4 || cfg.RAGMinScore != 0.3 || cfg.RAGChunkRunes != 800 {
		t.Errorf("cfg=%+v err=%v", cfg, err)
	}
	if badErr == nil || !strings.Contains(badErr.Error(), "RAG_MIN_SCORE") || !strings.Contains(badErr.Error(), "RAG_TOP_K") {
		t.Errorf("badErr = %v", badErr)
	}
}

func TestLoad_TimezoneAndAttachmentMessage(t *testing.T) {
	// Arrange
	env := requiredEnv()
	bad := requiredEnv()
	bad["TIMEZONE"] = "Mars/Olympus"

	// Act
	cfg, err := Load(lookupFrom(env))
	_, badErr := Load(lookupFrom(bad))

	// Assert
	if err != nil || cfg.Location == nil || cfg.Location.String() != "Asia/Bangkok" || cfg.AttachmentMessage == "" {
		t.Fatalf("defaults: location %v, attachment %q, err %v", cfg.Location, cfg.AttachmentMessage, err)
	}
	if badErr == nil || !strings.Contains(badErr.Error(), "TIMEZONE") {
		t.Errorf("unknown TIMEZONE error = %v", badErr)
	}
}

func TestLoad_Tracing(t *testing.T) {
	// Arrange
	on := requiredEnv()
	on["LANGFUSE_BASE_URL"], on["LANGFUSE_PUBLIC_KEY"], on["LANGFUSE_SECRET_KEY"] = "https://jp.cloud.langfuse.com/", "pk-lf-1", "sk-lf-2"
	half := requiredEnv()
	half["LANGFUSE_PUBLIC_KEY"] = "pk-lf-1"
	badText := requiredEnv()
	badText["TRACE_TEXT"] = "full"

	// Act
	off, errOff := Load(lookupFrom(requiredEnv()))
	cfg, errOn := Load(lookupFrom(on))
	_, errHalf := Load(lookupFrom(half))
	_, errBad := Load(lookupFrom(badText))

	// Assert
	if errOff != nil || off.TracingEnabled() {
		t.Errorf("no keys must mean tracing off: %v", errOff)
	}
	if errOn != nil || !cfg.TracingEnabled() || cfg.LangfuseBaseURL != "https://jp.cloud.langfuse.com" || cfg.TraceText != "redacted" {
		t.Errorf("tracing on: %+v %v", cfg, errOn)
	}
	if errHalf == nil || !strings.Contains(errHalf.Error(), "LANGFUSE_SECRET_KEY") {
		t.Errorf("a partial key set must fail and name what is missing: %v", errHalf)
	}
	if errBad == nil || !strings.Contains(errBad.Error(), "TRACE_TEXT") {
		t.Errorf("TRACE_TEXT=full must fail: %v", errBad)
	}
}

func TestNormalizeEmail_ConfigMatchesAccess(t *testing.T) {
	if got, ok := normalizeEmail(" John@Example.COM "); !ok || got != "john@example.com" {
		t.Fatalf("got %q %v", got, ok)
	}
	if _, ok := normalizeEmail("\u212Aate@corp.com"); ok {
		t.Fatal("non-ASCII owner email accepted")
	}
}

func TestDefaultMessagesMatchThePageVoice(t *testing.T) {
	// Arrange: the page speaks as ครับ, and nobody may be online to answer
	// "in a moment" (night, weekend).
	msgs := map[string]string{
		"handoff":    DefaultHandoffMessage,
		"attachment": DefaultAttachmentMessage,
		"failure":    DefaultFailureMessage,
	}

	// Act + Assert
	for name, m := range msgs {
		if !strings.Contains(m, "ครับ") {
			t.Errorf("%s message %q must use ครับ", name, m)
		}
		for _, bad := range []string{"ค่ะ", "นะคะ", "รอสักครู่", "โดยเร็ว"} {
			if strings.Contains(m, bad) {
				t.Errorf("%s message %q must not say %q", name, m, bad)
			}
		}
		if !strings.Contains(m, "ในแชทนี้") {
			t.Errorf("%s message %q must say staff answer in this chat", name, m)
		}
	}
}

func TestLoad_ReplyDelay(t *testing.T) {
	// Arrange
	lookup := func(extra map[string]string) func(string) (string, bool) {
		m := map[string]string{"CHATWOOT_BASE_URL": "http://x", "CHATWOOT_BOT_TOKEN": "t", "CHATWOOT_WEBHOOK_SECRET": "s"}
		for k, v := range extra {
			m[k] = v
		}
		return func(k string) (string, bool) { v, ok := m[k]; return v, ok }
	}

	// Act
	def, errDef := Load(lookup(nil))
	off, errOff := Load(lookup(map[string]string{"REPLY_DELAY": "0s"}))
	_, errBad := Load(lookup(map[string]string{"REPLY_DELAY": "2m"}))
	_, errNeg := Load(lookup(map[string]string{"REPLY_DELAY": "-1s"}))

	// Assert
	if errDef != nil || def.ReplyDelay != 4*time.Second {
		t.Errorf("default = %v %v, want 4s", def.ReplyDelay, errDef)
	}
	if errOff != nil || off.ReplyDelay != 0 {
		t.Errorf("0s must turn waiting off: %v %v", off.ReplyDelay, errOff)
	}
	if errBad == nil || errNeg == nil {
		t.Error("delays over 30s or below 0 must be refused")
	}
}

func TestFailureMessageDoesNotMentionTheSystem(t *testing.T) {
	// Act + Assert: the owner does not want customers told a system failed.
	for _, bad := range []string{"ระบบ", "อัตโนมัติ", "ขัดข้อง", "บอท", "AI"} {
		if strings.Contains(DefaultFailureMessage, bad) {
			t.Errorf("failure message %q must not say %q", DefaultFailureMessage, bad)
		}
	}
}
