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

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/bot"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/chatwoot"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/config"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/handoff"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/llm"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/memory"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/server"
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

	b := bot.New(bot.Options{
		Chatwoot:       chatwoot.New(cfg.ChatwootBaseURL, cfg.ChatwootBotToken, nil),
		LLM:            llm.New(cfg.LLMBaseURL, cfg.LLMAPIKey, cfg.LLMModel, &http.Client{Timeout: cfg.LLMTimeout}),
		History:        memory.NewHistory(cfg.HistoryLimit, 24*time.Hour, nil),
		Handoff:        handoff.New(cfg.HandoffKeywords),
		SystemPrompt:   cfg.SystemPrompt,
		HandoffMessage: cfg.HandoffMessage,
		FailureMessage: cfg.FailureMessage,
		Logger:         logger,
		Timeout:        cfg.LLMTimeout + 30*time.Second,
	}, cfg.Workers, cfg.QueueSize)
	b.Start(context.Background())

	h := &server.Handler{
		Secret: cfg.WebhookSecret,
		Queue:  b,
		Seen:   memory.NewSeen(30*time.Minute, nil),
		Logger: logger,
	}
	srv := &http.Server{
		Addr:              cfg.ListenAddr,
		Handler:           h.Routes(),
		ReadHeaderTimeout: 10 * time.Second,
		ReadTimeout:       30 * time.Second,
		WriteTimeout:      30 * time.Second,
	}

	errCh := make(chan error, 1)
	go func() {
		logger.Info("ai-service listening", "addr", cfg.ListenAddr, "model", cfg.LLMModel, "workers", cfg.Workers)
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
