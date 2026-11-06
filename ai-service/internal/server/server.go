// Package server exposes the HTTP endpoints: the Chatwoot webhook and health checks.
package server

import (
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/bot"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/memory"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/webhook"
)

// MaxBodyBytes caps webhook bodies.
const MaxBodyBytes = 1 << 20

// Enqueuer accepts jobs for async processing.
type Enqueuer interface {
	Enqueue(bot.Job) error
}

// Handler serves ai-service HTTP traffic.
type Handler struct {
	Secret string
	Queue  Enqueuer
	Seen   *memory.Seen
	Logger *slog.Logger
	Now    func() time.Time
}

// Routes returns the HTTP mux.
func (h *Handler) Routes() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("POST /webhooks/chatwoot", h.webhook)
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("ok"))
	})
	return mux
}

// webhook verifies, filters and enqueues an Agent Bot event, then returns
// immediately so Chatwoot's webhook job is not held open by the LLM call.
func (h *Handler) webhook(w http.ResponseWriter, r *http.Request) {
	deliveryID := r.Header.Get("X-Chatwoot-Delivery")
	log := h.Logger.With("delivery_id", deliveryID)

	body, err := io.ReadAll(http.MaxBytesReader(w, r.Body, MaxBodyBytes))
	if err != nil {
		http.Error(w, "body too large", http.StatusRequestEntityTooLarge)
		return
	}
	now := time.Now
	if h.Now != nil {
		now = h.Now
	}
	if err := webhook.Verify(h.Secret, r.Header.Get("X-Chatwoot-Timestamp"), r.Header.Get("X-Chatwoot-Signature"), body, now()); err != nil {
		log.Warn("rejected webhook", "error", err, "remote_addr", r.RemoteAddr)
		http.Error(w, "invalid signature", http.StatusUnauthorized)
		return
	}
	ev, err := webhook.Parse(body)
	if err != nil {
		log.Warn("invalid webhook json", "error", err)
		http.Error(w, "invalid json", http.StatusBadRequest)
		return
	}

	decision := webhook.Classify(ev)
	if decision == webhook.Ignore {
		w.WriteHeader(http.StatusOK)
		return
	}

	key := dedupeKey(ev)
	if !h.Seen.FirstTime(key) {
		log.Info("duplicate webhook ignored", "key", key)
		w.WriteHeader(http.StatusOK)
		return
	}
	if err := h.Queue.Enqueue(bot.Job{Event: ev, Decision: decision, DeliveryID: deliveryID}); err != nil {
		h.Seen.Release(key)
		if errors.Is(err, bot.ErrQueueFull) {
			// Chatwoot retries agent bot webhooks on 429 (lib/webhooks/trigger.rb).
			log.Warn("queue full, asking chatwoot to retry", "account_id", ev.Account.ID)
			http.Error(w, "busy", http.StatusTooManyRequests)
			return
		}
		log.Error("enqueue failed", "error", err)
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusAccepted)
}

func dedupeKey(ev webhook.Event) string {
	if ev.Event == "message_created" {
		return fmt.Sprintf("msg:%d:%d", ev.Account.ID, ev.ID)
	}
	return fmt.Sprintf("%s:%d:%d:%s", ev.Event, ev.Account.ID, ev.ID, ev.Status)
}
