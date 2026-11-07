// Package server exposes the HTTP endpoints: the Chatwoot webhook and health checks.
package server

import (
	"context"
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

// PlaceRecorder remembers account and inbox names (places.Recorder).
type PlaceRecorder interface {
	Record(ctx context.Context, accountID int64, accountName string, inboxID int64, inboxName string) error
}

// Handler serves ai-service HTTP traffic.
type Handler struct {
	Secret string
	Queue  Enqueuer
	Seen   *memory.Seen
	Logger *slog.Logger
	Now    func() time.Time
	// Places records the account and inbox names of signed webhooks; nil skips it.
	Places PlaceRecorder
}

// Routes returns the HTTP mux; callers may register more routes on it.
func (h *Handler) Routes() *http.ServeMux {
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
	h.recordPlace(r.Context(), ev)

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

// recordPlace saves the account and inbox names for the admin lists. It runs
// only after the signature check; a failure loses a name, never the message.
func (h *Handler) recordPlace(ctx context.Context, ev webhook.Event) {
	if h.Places == nil {
		return
	}
	ctx, cancel := context.WithTimeout(ctx, 2*time.Second)
	defer cancel()
	if err := h.Places.Record(ctx, ev.Account.ID, ev.Account.Name, ev.Inbox.ID, ev.Inbox.Name); err != nil {
		h.Logger.Warn("record inbox name failed", "account_id", ev.Account.ID, "inbox_id", ev.Inbox.ID, "error", err)
	}
}
