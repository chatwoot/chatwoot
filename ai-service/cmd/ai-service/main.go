// Command ai-service is the AI brain for Chatwoot: it receives Agent Bot
// webhooks, answers customers with an LLM and hands off to humans.
package main

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"net/url"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"
	_ "time/tzdata" // the distroless image has no zoneinfo; TIMEZONE needs it

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/admin"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/audit"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/bot"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/cfaccess"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/chatwoot"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/config"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/embed"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/handoff"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/llm"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/mcp"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/media"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/memory"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/oauth"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/places"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/profile"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/server"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/settings"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/trace"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/webfetch"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/websync"
)

func main() {
	if err := run(); err != nil {
		slog.Error("ai-service stopped", "error", err)
		os.Exit(1)
	}
}

func run() error {
	cfg, err := config.FromEnv()
	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: parseLevel(cfg.LogLevel)}))
	slog.SetDefault(logger)
	if err != nil {
		return err
	}

	// Env gives the initial provider settings; a saved settings file wins.
	store, err := settings.Open(cfg.SettingsPath, settings.Defaults(cfg))
	if err != nil {
		return err
	}
	current := store.Get()
	if err := current.Fallback.Validate(); err != nil {
		logger.Warn("fallback provider incomplete, fallback disabled", "error", err)
	}
	if !current.Primary.Configured() {
		logger.Warn("no LLM provider configured: every chat is handed to a human until one is set on /admin")
	}
	completer := &llm.Switch{}
	completer.Set(settings.NewCompleter(current, cfg.LLMTimeout, logger))
	// The query rewrite can run on a smaller, faster model (REWRITE_MODEL).
	rewriteLLM := &llm.Switch{}
	rewriteLLM.Set(settings.NewCompleter(settings.RewriteSettings(current, cfg.RewriteModel), cfg.LLMTimeout, logger))
	embedder := &embed.Switch{}
	embedder.Set(settings.NewEmbedder(current, cfg.LLMTimeout))

	kb, profiles, closeKB, err := openKnowledge(cfg, embedder, logger)
	if err != nil {
		return err
	}
	defer closeKB()
	// Assign only when set: a nil pointer in an interface is not a nil interface.
	var retriever bot.Retriever
	var botProfiles bot.Profiles
	var adminProfiles profile.Store
	var rewriter bot.QueryRewriter
	var usage bot.UsageRecorder
	var mcpStore *mcp.Postgres
	var oauthStore *oauth.Postgres
	if kb != nil {
		mcpStore = &mcp.Postgres{Pool: profiles.Pool}
		oauthStore = &oauth.Postgres{Pool: profiles.Pool}
		retriever, botProfiles, adminProfiles, usage = kb, profiles, profiles, kb
		rewriter = &bot.LLMRewriter{LLM: rewriteLLM}
	}

	// Tracing: assign the interface only when on (a nil pointer is not a nil interface).
	var tracer bot.Tracer
	var exporter *trace.Exporter
	if cfg.TracingEnabled() {
		exporter = trace.NewExporter(trace.Config{
			BaseURL: cfg.LangfuseBaseURL, PublicKey: cfg.LangfusePublicKey, SecretKey: cfg.LangfuseSecretKey,
			PseudonymKey: trace.PseudonymKey(cfg.WebhookSecret),
			Text:         cfg.TraceText, Environment: cfg.TraceEnvironment,
		}, logger)
		tracer = exporter
		logger.Info("langfuse tracing on", "host", hostOf(cfg.LangfuseBaseURL), "text", cfg.TraceText)
	}

	// Website pages kept in sync with the knowledge base (checked every 10 min for due pages).
	var webSyncer *websync.Syncer
	if kb != nil {
		webSyncer = &websync.Syncer{Store: &websync.Postgres{Pool: profiles.Pool}, Knowledge: kb, Fetcher: &webfetch.Fetcher{},
			Events: adminEvents(profiles, cfg.AuditRetentionDays), Logger: logger.With("component", "websync")}
	}

	b := bot.New(bot.Options{
		Chatwoot:          chatwoot.New(cfg.ChatwootBaseURL, cfg.ChatwootBotToken, nil),
		LLM:               completer,
		Knowledge:         retriever,
		Usage:             usage,
		Profiles:          botProfiles,
		Rewriter:          rewriter,
		Fetcher:           &media.Fetcher{Host: hostOf(cfg.ChatwootBaseURL), MaxBytes: 10 << 20},
		Transcriber:       liveTranscriber{store: store, model: cfg.TranscribeModel},
		StickerLLM:        rewriteLLM,
		Tracer:            tracer,
		History:           memory.NewHistory(cfg.HistoryLimit, 24*time.Hour, nil),
		Handoff:           handoff.New(cfg.HandoffKeywords),
		SystemPrompt:      cfg.SystemPrompt,
		HandoffMessage:    cfg.HandoffMessage,
		FailureMessage:    cfg.FailureMessage,
		AttachmentMessage: cfg.AttachmentMessage,
		Location:          cfg.Location,
		Logger:            logger,
		// Primary + fallback calls, plus Chatwoot API calls.
		Timeout: 2*cfg.LLMTimeout + 30*time.Second,
	}, cfg.Workers, cfg.QueueSize)
	b.Start(context.Background())
	if webSyncer != nil {
		go webSyncer.Run(context.Background(), 10*time.Minute)
	}

	h := &server.Handler{
		Secret: cfg.WebhookSecret,
		Queue:  b,
		Seen:   memory.NewSeen(30*time.Minute, nil),
		Logger: logger,
	}
	placeStore := placesStore(profiles)
	if placeStore != nil {
		h.Places = &places.Recorder{Store: placeStore}
	}
	mux := h.Routes()
	if cfg.AdminPassword != "" {
		(&admin.Handler{
			Password: cfg.AdminPassword, Store: store, Switch: completer, Embedder: embedder,
			Rewrite: rewriteLLM, RewriteModel: cfg.RewriteModel,
			Knowledge: kb, Profiles: adminProfiles, Tester: b, Location: cfg.Location, Timeout: cfg.LLMTimeout,
			Tokens: mcpTokens(mcpStore), Apps: oauthApps(oauthStore), MCPURL: cfg.MCPPublicURL,
			TeamSignIn: cfg.CFAccessAUD != "", Owners: cfg.Owners, AdminAccess: adminAccess(cfg),
			Events: adminEvents(profiles, cfg.AuditRetentionDays),
			Web:    webStore(profiles), WebSync: webSyncer, Places: adminPlaces(placeStore), Logger: logger,
		}).Routes(mux)
	} else {
		logger.Info("admin page disabled: set ADMIN_PASSWORD to enable /admin")
	}
	switch {
	case !cfg.MCPEnabled:
		logger.Info("mcp off: set MCP_ENABLED=true to let AI tools use the knowledge base")
	case mcpStore == nil || cfg.AdminPassword == "":
		logger.Warn("mcp off: it needs DATABASE_URL and ADMIN_PASSWORD (tokens are managed on /admin)")
	default:
		// MCP for AI tools: bearer-token auth inside, no /admin password.
		srvMCP := &mcp.Server{
			Knowledge: kb, Tokens: mcpStore, Audit: mcpStore, Tester: b,
			Location: cfg.Location, Logger: logger.With("component", "mcp"), Version: "1",
		}
		// OAuth lets Claude and ChatGPT apps connect with a sign-in instead of
		// a pasted token. It needs the public https address of /mcp.
		if strings.HasPrefix(cfg.MCPPublicURL, "https://") || strings.HasPrefix(cfg.MCPPublicURL, "http://127.0.0.1:") {
			as := &oauth.Server{Resource: cfg.MCPPublicURL, Password: cfg.AdminPassword,
				Store: oauthStore, Logger: logger.With("component", "oauth")}
			if cfg.CFAccessAUD != "" {
				// Team members signed in through Cloudflare Access approve apps; no password.
				as.Access = &cfaccess.Verifier{TeamDomain: cfg.CFAccessTeamDomain, AUD: cfg.CFAccessAUD}
				as.Owners = cfg.Owners
				logger.Info("mcp oauth approvals by team members (cloudflare access)", "team_domain", hostOf(cfg.CFAccessTeamDomain))
			}
			as.Routes(mux)
			srvMCP.ResourceMetadata = as.MetadataURL()
			logger.Info("mcp oauth on", "issuer", as.Issuer())
		} else {
			logger.Info("mcp oauth off: set MCP_PUBLIC_URL to the https address of /mcp")
		}
		mux.Handle("/mcp", srvMCP)
		logger.Info("mcp on", "path", "/mcp")
	}
	srv := &http.Server{
		Addr:              cfg.ListenAddr,
		Handler:           mux,
		ReadHeaderTimeout: 10 * time.Second,
		ReadTimeout:       30 * time.Second,
		// The admin test chat waits for a full bot reply (the bot Timeout set above).
		WriteTimeout: 2*cfg.LLMTimeout + 45*time.Second,
	}

	errCh := make(chan error, 1)
	go func() {
		logger.Info("ai-service listening", "addr", cfg.ListenAddr,
			"primary_model", current.Primary.Model, "rewrite_model", settings.RewriteSettings(current, cfg.RewriteModel).Primary.Model, "fallback_enabled", current.Fallback.Configured(),
			"admin_enabled", cfg.AdminPassword != "", "workers", cfg.Workers,
			"knowledge_enabled", kb != nil, "embedding_model", embedder.Model())
		errCh <- srv.ListenAndServe()
	}()

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)
	select {
	case err := <-errCh:
		if !errors.Is(err, http.ErrServerClosed) {
			return err
		}
	case sig := <-stop:
		logger.Info("shutting down", "signal", sig.String())
	}

	// Stop taking webhooks first, then drain queued jobs.
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		logger.Warn("http shutdown", "error", err)
	}
	b.Close()
	exporter.Close() // after the bot, so the last turns are sent
	return nil
}

// liveTranscriber builds the transcriber from the saved provider settings on
// every call, so a key changed on /admin applies without a restart.
type liveTranscriber struct {
	store *settings.Store
	model string
}

func (t liveTranscriber) Transcribe(ctx context.Context, audio []byte, filename, hint string) (string, error) {
	p := t.store.Get().Primary
	return (&media.Transcriber{BaseURL: p.BaseURL, APIKey: p.APIKey, Model: t.model, Prompt: hint}).Transcribe(ctx, audio, filename)
}

func hostOf(raw string) string {
	if u, err := url.Parse(raw); err == nil {
		return u.Host
	}
	return ""
}

// openKnowledge connects the knowledge base and business profiles when
// DATABASE_URL is set. Without it the bot answers from the system prompt only.
func openKnowledge(cfg config.Config, embedder embed.Embedder, logger *slog.Logger) (*knowledge.Service, *profile.Postgres, func(), error) {
	if cfg.DatabaseURL == "" {
		logger.Info("knowledge base and business profiles disabled: set DATABASE_URL to enable them")
		return nil, nil, func() {}, nil
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	pg, err := knowledge.OpenPostgres(ctx, cfg.DatabaseURL)
	if err != nil {
		return nil, nil, nil, err
	}
	if embedder.Model() == "" {
		logger.Warn("knowledge base on, but no embeddings provider: set one on /admin so the bot can search it")
	}
	return &knowledge.Service{
		Store: pg, Embedder: embedder,
		TopK: cfg.RAGTopK, MinScore: cfg.RAGMinScore, ChunkRunes: cfg.RAGChunkRunes,
	}, &profile.Postgres{Pool: pg.Pool}, pg.Pool.Close, nil
}

// webStore is the website pages store, or nil without a database.
func webStore(p *profile.Postgres) websync.Store {
	if p == nil {
		return nil
	}
	return &websync.Postgres{Pool: p.Pool}
}

// adminEvents is the admin change log, or nil without a database.
func adminEvents(p *profile.Postgres, retentionDays int) audit.Store {
	if p == nil {
		return nil
	}
	return &audit.Postgres{Pool: p.Pool, RetentionDays: retentionDays}
}

// placesStore remembers Chatwoot account and inbox names, or nil without a database.
func placesStore(p *profile.Postgres) *places.Postgres {
	if p == nil {
		return nil
	}
	return &places.Postgres{Pool: p.Pool}
}

// adminPlaces keeps a nil store a nil interface.
func adminPlaces(p *places.Postgres) admin.Places {
	if p == nil {
		return nil
	}
	return p
}

// adminAccess is the /admin Access verifier, or nil (password only).
func adminAccess(cfg config.Config) admin.Identifier {
	if cfg.CFAccessAdminAUD == "" {
		return nil
	}
	return &cfaccess.Verifier{TeamDomain: cfg.CFAccessTeamDomain, AUD: cfg.CFAccessAdminAUD}
}

// oauthApps keeps a nil store a nil interface.
func oauthApps(p *oauth.Postgres) oauth.Store {
	if p == nil {
		return nil
	}
	return p
}

// mcpTokens keeps a nil store a nil interface, so the admin hides the page.
func mcpTokens(p *mcp.Postgres) mcp.Tokens {
	if p == nil {
		return nil
	}
	return p
}

func parseLevel(s string) slog.Level {
	switch strings.ToLower(s) {
	case "debug":
		return slog.LevelDebug
	case "warn":
		return slog.LevelWarn
	case "error":
		return slog.LevelError
	default:
		return slog.LevelInfo
	}
}
