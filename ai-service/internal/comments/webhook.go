package comments

import (
	"context"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"time"
)

// MaxBodyBytes caps a webhook body. Meta batches events, but a feed delivery
// is far below this.
const MaxBodyBytes = 1 << 20

// WebhookPath is where Meta sends Page webhooks. It must be reachable from
// the internet without a sign-in; the signature is the authentication.
const WebhookPath = "/webhooks/meta"

// Webhook receives the Page feed webhook.
type Webhook struct {
	AppSecret   string // Meta app secret: verifies X-Hub-Signature-256
	VerifyToken string // our token for Meta's subscription check
	PageID      string // the only Page whose comments are accepted
	AccountID   int64  // the Chatwoot account the Page belongs to
	Store       Store
	Logger      *slog.Logger
}

// Routes registers the webhook on mux.
func (h *Webhook) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET "+WebhookPath, h.handshake)
	mux.HandleFunc("POST "+WebhookPath, h.receive)
}

func (h *Webhook) handshake(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	challenge, ok := Handshake(h.VerifyToken, q.Get("hub.mode"), q.Get("hub.verify_token"), q.Get("hub.challenge"))
	if !ok {
		h.Logger.Debug("meta webhook check refused", "remote_addr", r.RemoteAddr)
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	w.Header().Set("X-Content-Type-Options", "nosniff")
	_, _ = io.WriteString(w, challenge)
}

// receive verifies, parses and stores comment events. It answers 200 for
// anything signed, even events it skips, so Meta does not retry them; a
// storage failure answers 500 so Meta retries the delivery later.
func (h *Webhook) receive(w http.ResponseWriter, r *http.Request) {
	body, err := io.ReadAll(http.MaxBytesReader(w, r.Body, MaxBodyBytes))
	if err != nil {
		http.Error(w, "body too large", http.StatusRequestEntityTooLarge)
		return
	}
	if err := VerifySignature(h.AppSecret, r.Header.Get("X-Hub-Signature-256"), body); err != nil {
		// Debug, not Warn: anyone can POST here, and that must not flood the logs.
		h.Logger.Debug("rejected meta webhook", "error", err, "remote_addr", r.RemoteAddr)
		http.Error(w, "invalid signature", http.StatusUnauthorized)
		return
	}
	changes, err := Parse(body, h.PageID)
	if err != nil {
		h.Logger.Warn("invalid meta webhook json", "error", err)
		http.Error(w, "invalid json", http.StatusBadRequest)
		return
	}
	// Finish storing even if Meta hangs up; the work is a few small writes.
	ctx, cancel := context.WithTimeout(context.WithoutCancel(r.Context()), 10*time.Second)
	defer cancel()
	for _, ch := range changes {
		err := h.apply(ctx, ch)
		if errors.Is(err, ErrRejected) {
			// A retry would fail the same way and hold back the rest of the batch.
			h.Logger.Warn("page comment skipped: the database refused it", "account_id", h.AccountID, "comment_id", ch.Comment.CommentID, "error", err)
			continue
		}
		if err != nil {
			h.Logger.Error("store page comment", "account_id", h.AccountID, "comment_id", ch.Comment.CommentID, "error", err)
			http.Error(w, "internal error", http.StatusInternalServerError)
			return
		}
	}
	w.WriteHeader(http.StatusOK)
}

func (h *Webhook) apply(ctx context.Context, ch Change) error {
	c := ch.Comment
	c.AccountID = h.AccountID
	if ch.Verb == "remove" {
		return h.Store.Forget(ctx, c)
	}
	added, err := h.Store.Add(ctx, c)
	if err == nil && added {
		h.Logger.Info("page comment received", "account_id", h.AccountID, "comment_id", c.CommentID)
	}
	return err
}
