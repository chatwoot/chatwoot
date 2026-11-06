// Command ai-service is the AI brain for Chatwoot: it receives Agent Bot
// webhooks, answers customers with an LLM and hands off to humans.
package main

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/admin"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/bot"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/chatwoot"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/config"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/handoff"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/llm"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/memory"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/server"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/settings"
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
	store, err := settings.Open(cfg.SettingsPath, settings.LLM{
		Primary:  settings.Provider{BaseURL: cfg.LLMBaseURL, APIKey: cfg.LLMAPIKey, Model: cfg.LLMModel},
		Fallback: settings.Provider{BaseURL: cfg.LLMFallbackBaseURL, APIKey: cfg.LLMFallbackAPIKey, Model: cfg.LLMFallbackModel},
	})
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

	b := bot.New(bot.Options{
		Chatwoot:       chatwoot.New(cfg.ChatwootBaseURL, cfg.ChatwootBotToken, nil),
		LLM:            completer,
		History:        memory.NewHistory(cfg.HistoryLimit, 24*time.Hour, nil),
		Handoff:        handoff.New(cfg.HandoffKeywords),
		SystemPrompt:   cfg.SystemPrompt,
		HandoffMessage: cfg.HandoffMessage,
		FailureMessage: cfg.FailureMessage,
		Logger:         logger,
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
			Password: cfg.AdminPassword, Store: store, Switch: completer,
			Timeout: cfg.LLMTimeout, Logger: logger,
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
			"admin_enabled", cfg.AdminPassword != "", "workers", cfg.Workers)
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
	return nil
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
