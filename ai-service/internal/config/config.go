// Package config loads ai-service settings from environment variables.
package config

import (
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/trace"

	"errors"
	"fmt"
	"os"
	"regexp"
	"strconv"
	"strings"
	"time"
)

// Config holds every runtime setting. Secrets are never logged.
type Config struct {
	ListenAddr string

	ChatwootBaseURL string
	// ChatwootPublicURL is the address Chatwoot writes into attachment links
	// (its FRONTEND_URL) when the bot reaches Chatwoot by another one, as in
	// Docker. Optional.
	ChatwootPublicURL string
	ChatwootBotToken  string // Agent Bot access token (secret)
	// ChatwootReaderToken is an agent account's token, used only to read a
	// chat's recent messages (bot tokens cannot). Optional (secret).
	ChatwootReaderToken string
	WebhookSecret       string // Agent Bot webhook secret used for HMAC (secret)

	// Initial LLM settings; the admin page can override them at runtime.
	LLMBaseURL         string
	LLMAPIKey          string // secret
	LLMModel           string
	LLMFallbackBaseURL string
	LLMFallbackAPIKey  string // secret
	LLMFallbackModel   string
	LLMTimeout         time.Duration // per provider call
	ReplyDelay         time.Duration // wait after a customer's last message, so quick messages get one reply
	SystemPrompt       string

	AdminPassword string // enables /admin when set (secret)
	SettingsPath  string

	// Knowledge base (RAG). Off when DatabaseURL is empty.
	DatabaseURL          string // Postgres with pgvector (secret: contains a password)
	EmbedBaseURL         string // initial embeddings provider; the admin page can override it
	EmbedAPIKey          string // secret
	EmbedModel           string
	EmbedFallbackBaseURL string // same embedding model through another provider (optional)
	EmbedFallbackAPIKey  string // secret
	EmbedFallbackModel   string
	RAGTopK              int
	RAGMinScore          float64
	RAGChunkRunes        int

	HandoffKeywords []string
	HandoffMessage  string
	FailureMessage  string
	// AttachmentMessage answers a message that is only files (slip, photo, voice).
	AttachmentMessage string
	// Langfuse tracing: on only when all three are set (the secret key is a secret).
	LangfuseBaseURL, LangfusePublicKey, LangfuseSecretKey string
	TraceText                                             string // redacted (default) | off
	TraceEnvironment                                      string
	// RewriteModel runs the query rewrite on a smaller, faster model of the
	// main provider (REWRITE_MODEL); empty uses the main model.
	RewriteModel string
	// TranscribeModel turns voice notes into text (TRANSCRIBE_MODEL) on the
	// main provider's /audio/transcriptions endpoint.
	TranscribeModel string
	// MCPPublicURL is the MCP address shown on the admin connections page
	// (MCP_PUBLIC_URL); empty derives it from the admin request.
	MCPPublicURL string
	// MCPEnabled serves /mcp for AI tools (MCP_ENABLED, default false). It
	// also needs a database and the admin page (ADMIN_PASSWORD) to manage tokens.
	MCPEnabled bool
	// CFAccessTeamDomain (https://<team>.cloudflareaccess.com) and CFAccessAUD
	// (the approval page's Access application AUD tag) switch app approval
	// from the admin password to team members signed in through Access.
	CFAccessTeamDomain, CFAccessAUD string
	// CFAccessAdminAUD is the AUD tag of the Access application in front of
	// /admin; with Owners (ADMIN_EMAILS) it lets the owner in without the
	// password (for example signed in with GitHub through Access).
	CFAccessAdminAUD string
	Owners           []string
	// AuditRetentionDays: change-log entries (including old document text)
	// older than this are deleted (AUDIT_RETENTION_DAYS, default 180).
	AuditRetentionDays int
	// Location is the business time zone (TIMEZONE), used to tell the model the date.
	Location *time.Location

	// Facebook Page comments (/webhooks/meta, /admin/comments): on when the
	// app secret, verify token and Page ID are set, with a database.
	MetaAppSecret    string // verifies Meta's webhook signature (secret)
	MetaVerifyToken  string // our token for Meta's subscription check (secret)
	MetaPageID       string
	MetaPageToken    string // Page access token for private replies; empty: no sending (secret)
	MetaAccountID    int64  // the Chatwoot account the Page belongs to (default 1)
	MetaGraphVersion string // Graph API version, e.g. v24.0
	// CommentReviewer is the shadow reviewer of drafted replies: off, llm
	// (the main provider, or CommentReviewModel on it) or jev (TypeSafe).
	// It only records what it would do; it never sends.
	CommentReviewer    string
	CommentReviewModel string
	TypeSafeAPIKey     string // for COMMENT_REVIEWER=jev (secret)
	TypeSafeModel      string

	HistoryLimit int
	Workers      int
	QueueSize    int
	LogLevel     string
}

// DefaultSystemPrompt is used when SYSTEM_PROMPT is not set.
const DefaultSystemPrompt = "You are a friendly customer support assistant. " +
	"Reply in the same language the customer uses (often Thai or Lao). " +
	"Keep answers short and clear. If you do not know the answer, say so honestly " +
	"and offer to connect the customer with a staff member. Never invent prices, " +
	"policies or order details."

// DefaultHandoffKeywords trigger a handoff to a human (Thai, Lao, English).
// They are request phrases, not bare words: "บริษัทมีพนักงานกี่คน" mentions
// staff without asking for them, and must still get an AI answer.
var DefaultHandoffKeywords = []string{
	"คุยกับคน", "ขอคุยกับแอดมิน", "ติดต่อแอดมิน", "ขอสายแอดมิน",
	"คุยกับเจ้าหน้าที่", "ติดต่อเจ้าหน้าที่", "ขอเจ้าหน้าที่", "ขอสายเจ้าหน้าที่",
	"คุยกับพนักงาน", "ติดต่อพนักงาน", "ขอพนักงาน", "ขอสายพนักงาน",
	"ລົມກັບຄົນ", "ລົມກັບພະນັກງານ", "ຕິດຕໍ່ພະນັກງານ", "ລົມກັບແອັດມິນ", "ຕິດຕໍ່ແອັດມິນ",
	"human", "real person", "talk to agent", "talk to a person", "live agent", "speak to someone",
}

// DefaultHandoffMessage is sent to the customer when the bot hands off. The
// default messages speak as the page does (ครับ) and promise no reply time:
// staff may be offline. They name the team, not a specialist: handoff assigns
// whoever is online with the fewest chats. HANDOFF_MESSAGE, ATTACHMENT_MESSAGE and
// FAILURE_MESSAGE override them.
const DefaultHandoffMessage = "ได้เลยครับ กำลังส่งต่อให้ทีมงานเข้ามาดูแลต่อในแชทนี้ครับ ระหว่างนี้พิมพ์รายละเอียดทิ้งไว้ได้เลย 🙏"

// DefaultAttachmentMessage acknowledges files the bot cannot read before handing off.
const DefaultAttachmentMessage = "ได้รับไฟล์แล้วครับ ไฟล์แบบนี้ผมเปิดดูเองไม่ได้ กำลังส่งต่อให้ทีมงานเข้ามาดูแลต่อในแชทนี้ครับ"

// DefaultFailureMessage is sent when the AI cannot answer (LLM error) before handing off.
const DefaultFailureMessage = "ขออภัยครับ เรื่องนี้ขอส่งต่อให้ทีมงานเข้ามาดูแลต่อในแชทนี้นะครับ 🙏"

// Load reads Config from the given lookup function (os.LookupEnv in production).
func Load(lookup func(string) (string, bool)) (Config, error) {
	get := func(key, def string) string {
		if v, ok := lookup(key); ok && strings.TrimSpace(v) != "" {
			return strings.TrimSpace(v)
		}
		return def
	}

	cfg := Config{
		ListenAddr:           get("LISTEN_ADDR", ":8080"),
		ChatwootBaseURL:      strings.TrimRight(get("CHATWOOT_BASE_URL", ""), "/"),
		ChatwootPublicURL:    strings.TrimRight(get("CHATWOOT_PUBLIC_URL", ""), "/"),
		ChatwootBotToken:     get("CHATWOOT_BOT_TOKEN", ""),
		ChatwootReaderToken:  get("CHATWOOT_READER_TOKEN", ""),
		WebhookSecret:        get("CHATWOOT_WEBHOOK_SECRET", ""),
		LLMBaseURL:           strings.TrimRight(get("LLM_BASE_URL", "https://openrouter.ai/api/v1"), "/"),
		LLMAPIKey:            get("LLM_API_KEY", ""),
		LLMModel:             get("LLM_MODEL", ""),
		LLMFallbackBaseURL:   strings.TrimRight(get("LLM_FALLBACK_BASE_URL", ""), "/"),
		LLMFallbackAPIKey:    get("LLM_FALLBACK_API_KEY", ""),
		LLMFallbackModel:     get("LLM_FALLBACK_MODEL", ""),
		AdminPassword:        get("ADMIN_PASSWORD", ""),
		SettingsPath:         get("SETTINGS_PATH", "/data/settings.json"),
		DatabaseURL:          get("DATABASE_URL", ""),
		EmbedBaseURL:         strings.TrimRight(get("EMBED_BASE_URL", ""), "/"),
		EmbedAPIKey:          get("EMBED_API_KEY", ""),
		EmbedModel:           get("EMBED_MODEL", ""),
		EmbedFallbackBaseURL: strings.TrimRight(get("EMBED_FALLBACK_BASE_URL", ""), "/"),
		EmbedFallbackAPIKey:  get("EMBED_FALLBACK_API_KEY", ""),
		EmbedFallbackModel:   get("EMBED_FALLBACK_MODEL", ""),
		SystemPrompt:         get("SYSTEM_PROMPT", DefaultSystemPrompt),
		HandoffMessage:       get("HANDOFF_MESSAGE", DefaultHandoffMessage),
		FailureMessage:       get("FAILURE_MESSAGE", DefaultFailureMessage),
		AttachmentMessage:    get("ATTACHMENT_MESSAGE", DefaultAttachmentMessage),
		LangfuseBaseURL:      strings.TrimRight(get("LANGFUSE_BASE_URL", ""), "/"),
		LangfusePublicKey:    get("LANGFUSE_PUBLIC_KEY", ""),
		LangfuseSecretKey:    get("LANGFUSE_SECRET_KEY", ""),
		TraceText:            get("TRACE_TEXT", "redacted"),
		TraceEnvironment:     get("TRACE_ENVIRONMENT", "production"),
		RewriteModel:         get("REWRITE_MODEL", ""),
		TranscribeModel:      get("TRANSCRIBE_MODEL", "gpt-4o-mini-transcribe"),
		LogLevel:             get("LOG_LEVEL", "info"),
		HandoffKeywords:      DefaultHandoffKeywords,
	}

	if raw := get("HANDOFF_KEYWORDS", ""); raw != "" {
		cfg.HandoffKeywords = splitList(raw)
	}

	var errs []error
	var err error
	if cfg.ReplyDelay, err = time.ParseDuration(get("REPLY_DELAY", "4s")); err != nil || cfg.ReplyDelay < 0 || cfg.ReplyDelay > 30*time.Second {
		errs = append(errs, fmt.Errorf("REPLY_DELAY must be a duration from 0s to 30s"))
	}
	if cfg.LLMTimeout, err = time.ParseDuration(get("LLM_TIMEOUT", "45s")); err != nil {
		errs = append(errs, fmt.Errorf("LLM_TIMEOUT: %w", err))
	}
	cfg.MCPPublicURL = get("MCP_PUBLIC_URL", "")
	cfg.MCPEnabled = get("MCP_ENABLED", "") == "true"
	cfg.CFAccessTeamDomain = strings.TrimSuffix(get("CF_ACCESS_TEAM_DOMAIN", ""), "/")
	cfg.CFAccessAUD = get("CF_ACCESS_AUD", "")
	cfg.CFAccessAdminAUD = get("CF_ACCESS_ADMIN_AUD", "")
	for _, e := range strings.Split(get("ADMIN_EMAILS", ""), ",") {
		if strings.TrimSpace(e) == "" {
			continue
		}
		n, ok := normalizeEmail(e)
		if !ok {
			errs = append(errs, fmt.Errorf("ADMIN_EMAILS: %q is not a plain ASCII email address", strings.TrimSpace(e)))
			continue
		}
		cfg.Owners = append(cfg.Owners, n)
	}
	if v := get("AUDIT_RETENTION_DAYS", "180"); v != "" {
		n, err := strconv.Atoi(v)
		if err != nil || n < 1 {
			errs = append(errs, errors.New("AUDIT_RETENTION_DAYS must be a positive number of days"))
		}
		cfg.AuditRetentionDays = n
	}
	if cfg.CFAccessAUD != "" && cfg.CFAccessTeamDomain == "" || cfg.CFAccessTeamDomain != "" && cfg.CFAccessAUD == "" && cfg.CFAccessAdminAUD == "" {
		errs = append(errs, errors.New("CF_ACCESS_TEAM_DOMAIN needs CF_ACCESS_AUD and/or CF_ACCESS_ADMIN_AUD, and they need it"))
	}
	if cfg.CFAccessAdminAUD != "" && (cfg.CFAccessTeamDomain == "" || len(cfg.Owners) == 0) {
		errs = append(errs, errors.New("CF_ACCESS_ADMIN_AUD needs CF_ACCESS_TEAM_DOMAIN and ADMIN_EMAILS"))
	}
	if cfg.CFAccessTeamDomain != "" && !strings.HasPrefix(cfg.CFAccessTeamDomain, "https://") {
		errs = append(errs, errors.New("CF_ACCESS_TEAM_DOMAIN must start with https://"))
	}
	if cfg.Location, err = time.LoadLocation(get("TIMEZONE", "Asia/Bangkok")); err != nil {
		errs = append(errs, fmt.Errorf("TIMEZONE: %w", err))
	}
	cfg.HistoryLimit, errs = intVar(get("HISTORY_LIMIT", "20"), "HISTORY_LIMIT", errs)
	cfg.Workers, errs = intVar(get("WORKERS", "4"), "WORKERS", errs)
	cfg.QueueSize, errs = intVar(get("QUEUE_SIZE", "256"), "QUEUE_SIZE", errs)
	cfg.RAGTopK, errs = intVar(get("RAG_TOP_K", "4"), "RAG_TOP_K", errs)
	cfg.RAGChunkRunes, errs = intVar(get("RAG_CHUNK_RUNES", "800"), "RAG_CHUNK_RUNES", errs)
	if cfg.RAGMinScore, err = strconv.ParseFloat(get("RAG_MIN_SCORE", "0.3"), 64); err != nil || cfg.RAGMinScore < -1 || cfg.RAGMinScore > 1 {
		errs = append(errs, errors.New("RAG_MIN_SCORE must be a number between -1 and 1"))
	}

	if cfg.TraceText != "redacted" && cfg.TraceText != "off" {
		errs = append(errs, errors.New("TRACE_TEXT must be redacted or off"))
	}
	lf := []struct{ key, val string }{
		{"LANGFUSE_BASE_URL", cfg.LangfuseBaseURL}, {"LANGFUSE_PUBLIC_KEY", cfg.LangfusePublicKey}, {"LANGFUSE_SECRET_KEY", cfg.LangfuseSecretKey},
	}
	if cfg.LangfuseBaseURL != "" {
		if err := trace.ValidateBaseURL(cfg.LangfuseBaseURL); err != nil {
			errs = append(errs, err)
		}
	}
	if set := lf[0].val != "" || lf[1].val != "" || lf[2].val != ""; set {
		for _, v := range lf {
			if v.val == "" {
				errs = append(errs, fmt.Errorf("%s is required when Langfuse tracing is configured", v.key))
			}
		}
	}

	errs = loadMeta(&cfg, get, errs)

	required := []struct{ key, val string }{
		{"CHATWOOT_BASE_URL", cfg.ChatwootBaseURL},
		{"CHATWOOT_BOT_TOKEN", cfg.ChatwootBotToken},
		{"CHATWOOT_WEBHOOK_SECRET", cfg.WebhookSecret},
	}
	for _, r := range required {
		if r.val == "" {
			errs = append(errs, fmt.Errorf("%s is required", r.key))
		}
	}
	if cfg.AdminPassword != "" && len(cfg.AdminPassword) < MinAdminPasswordLen {
		errs = append(errs, fmt.Errorf("ADMIN_PASSWORD must be at least %d characters", MinAdminPasswordLen))
	}
	return cfg, errors.Join(errs...)
}

// MinAdminPasswordLen is the shortest accepted ADMIN_PASSWORD.
const MinAdminPasswordLen = 12

// FromEnv loads Config from the process environment.
func FromEnv() (Config, error) { return Load(os.LookupEnv) }

func intVar(raw, key string, errs []error) (int, []error) {
	n, err := strconv.Atoi(raw)
	if err != nil || n < 1 {
		return 0, append(errs, fmt.Errorf("%s must be a positive integer", key))
	}
	return n, errs
}

func splitList(raw string) []string {
	var out []string
	for _, p := range strings.Split(raw, ",") {
		if p = strings.TrimSpace(p); p != "" {
			out = append(out, p)
		}
	}
	return out
}

var (
	digitsRe       = regexp.MustCompile(`^[0-9]{1,32}$`)
	graphVersionRe = regexp.MustCompile(`^v[0-9]{1,3}\.[0-9]{1,2}$`)
)

// loadMeta reads the Facebook Page comment settings. The app secret, verify
// token and Page ID come together; the Page token is optional (without it
// comments are queued but cannot be sent).
func loadMeta(cfg *Config, get func(key, def string) string, errs []error) []error {
	cfg.MetaAppSecret = get("META_APP_SECRET", "")
	cfg.MetaVerifyToken = get("META_VERIFY_TOKEN", "")
	cfg.MetaPageID = get("META_PAGE_ID", "")
	cfg.MetaPageToken = get("META_PAGE_TOKEN", "")
	cfg.MetaGraphVersion = get("META_GRAPH_VERSION", "v24.0")
	cfg.CommentReviewer = get("COMMENT_REVIEWER", "llm")
	cfg.CommentReviewModel = get("COMMENT_REVIEW_MODEL", "")
	cfg.TypeSafeAPIKey = get("TYPESAFE_API_KEY", "")
	cfg.TypeSafeModel = get("TYPESAFE_MODEL", "jev-latest")
	switch cfg.CommentReviewer {
	case "off", "llm":
	case "jev":
		if cfg.TypeSafeAPIKey == "" {
			errs = append(errs, errors.New("COMMENT_REVIEWER=jev needs TYPESAFE_API_KEY"))
		}
	default:
		errs = append(errs, errors.New("COMMENT_REVIEWER must be off, llm or jev"))
	}
	n, err := strconv.ParseInt(get("META_ACCOUNT_ID", "1"), 10, 64)
	if err != nil || n < 1 {
		errs = append(errs, errors.New("META_ACCOUNT_ID must be a positive Chatwoot account id"))
	}
	cfg.MetaAccountID = n
	set := cfg.MetaAppSecret != "" || cfg.MetaVerifyToken != "" || cfg.MetaPageID != "" || cfg.MetaPageToken != ""
	if !set {
		return errs
	}
	if cfg.MetaAppSecret == "" || cfg.MetaVerifyToken == "" || cfg.MetaPageID == "" {
		errs = append(errs, errors.New("META_APP_SECRET, META_VERIFY_TOKEN and META_PAGE_ID are required together"))
	}
	if cfg.MetaPageID != "" && !digitsRe.MatchString(cfg.MetaPageID) {
		errs = append(errs, errors.New("META_PAGE_ID must be the numeric Facebook Page id"))
	}
	if cfg.MetaVerifyToken != "" && len(cfg.MetaVerifyToken) < 16 {
		errs = append(errs, errors.New("META_VERIFY_TOKEN must be at least 16 characters"))
	}
	if !graphVersionRe.MatchString(cfg.MetaGraphVersion) {
		errs = append(errs, errors.New("META_GRAPH_VERSION must look like v24.0"))
	}
	return errs
}

// CommentsEnabled reports whether the Page comment webhook is configured.
func (c Config) CommentsEnabled() bool {
	return c.MetaAppSecret != "" && c.MetaVerifyToken != "" && c.MetaPageID != ""
}

// TracingEnabled reports whether every Langfuse setting is present.
func (c Config) TracingEnabled() bool {
	return c.LangfuseBaseURL != "" && c.LangfusePublicKey != "" && c.LangfuseSecretKey != ""
}

// normalizeEmail mirrors cfaccess.NormalizeEmail (config must not import it):
// ASCII only, trimmed, lower-cased by byte.
func normalizeEmail(raw string) (string, bool) {
	e := strings.TrimSpace(raw)
	if e == "" || len(e) > 320 || !strings.Contains(e, "@") {
		return "", false
	}
	b := []byte(e)
	for i, c := range b {
		switch {
		case c > 0x7e || c < 0x21:
			return "", false
		case c >= 'A' && c <= 'Z':
			b[i] = c + ('a' - 'A')
		}
	}
	return string(b), true
}
