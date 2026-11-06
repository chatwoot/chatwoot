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
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/bot"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/chatwoot"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/config"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/embed"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/handoff"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/llm"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/memory"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/profile"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/server"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/settings"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/trace"
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
	if kb != nil {
		retriever, botProfiles, adminProfiles = kb, profiles, profiles
		rewriter = &bot.LLMRewriter{LLM: completer}
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

	b := bot.New(bot.Options{
		Chatwoot:          chatwoot.New(cfg.ChatwootBaseURL, cfg.ChatwootBotToken, nil),
		LLM:               completer,
		Knowledge:         retriever,
		Profiles:          botProfiles,
		Rewriter:          rewriter,
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

	h := &server.Handler{
		Secret: cfg.WebhookSecret,
		Queue:  b,
		Seen:   memory.NewSeen(30*time.Minute, nil),
		Logger: logger,
	}
	mux := h.Routes()
	if cfg.AdminPassword != "" {
		(&admin.Handler{
			Password: cfg.AdminPassword, Store: store, Switch: completer, Embedder: embedder,
			Knowledge: kb, Profiles: adminProfiles, Timeout: cfg.LLMTimeout, Logger: logger,
		}).Routes(mux)
	} else {
		logger.Info("admin page disabled: set ADMIN_PASSWORD to enable /admin")
	}
	srv := &http.Server{
		Addr:              cfg.ListenAddr,
		Handler:           mux,
		ReadHeaderTimeout: 10 * time.Second,
		ReadTimeout:       30 * time.Second,
		// The admin "Test connection" button waits for one provider call.
		WriteTimeout: cfg.LLMTimeout + 15*time.Second,
	}

	errCh := make(chan error, 1)
	go func() {
		logger.Info("ai-service listening", "addr", cfg.ListenAddr,
			"primary_model", current.Primary.Model, "fallback_enabled", current.Fallback.Configured(),
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
