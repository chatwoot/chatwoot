package server

import (
	"encoding/hex"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/bot"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/memory"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/webhook"
)

const secret = "s3cret"

var fixedNow = time.Unix(1_800_000_000, 0)

const pendingMsg = `{"event":"message_created","id":42,"content":"hi","message_type":"incoming","private":false,
"account":{"id":1},"inbox":{"id":3},"sender":{"id":9,"type":"contact"},"conversation":{"id":7,"status":"pending"}}`

type fakeQueue struct {
	jobs []bot.Job
	err  error
}

func (q *fakeQueue) Enqueue(j bot.Job) error {
	if q.err != nil {
		return q.err
	}
	q.jobs = append(q.jobs, j)
	return nil
}

func newHandler(q *fakeQueue) http.Handler {
	h := &Handler{
		Secret: secret, Queue: q,
		Seen:   memory.NewSeen(10*time.Minute, nil),
		Logger: slog.New(slog.NewJSONHandler(io.Discard, nil)),
		Now:    func() time.Time { return fixedNow },
	}
	return h.Routes()
}

func signedRequest(body string) *http.Request {
	ts := strconv.FormatInt(fixedNow.Unix(), 10)
	req := httptest.NewRequest(http.MethodPost, "/webhooks/chatwoot", strings.NewReader(body))
	req.Header.Set("X-Chatwoot-Timestamp", ts)
	req.Header.Set("X-Chatwoot-Signature", "sha256="+hex.EncodeToString(webhook.Sign(secret, ts, []byte(body))))
	req.Header.Set("X-Chatwoot-Delivery", "d-1")
	return req
}

func do(h http.Handler, r *http.Request) int {
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, r)
	return rec.Code
}

func TestWebhook_AcceptsAndEnqueuesCustomerMessage(t *testing.T) {
	// Arrange
	q := &fakeQueue{}
	h := newHandler(q)

	// Act
	code := do(h, signedRequest(pendingMsg))

	// Assert
	if code != http.StatusAccepted || len(q.jobs) != 1 {
		t.Fatalf("code=%d jobs=%d", code, len(q.jobs))
	}
	if q.jobs[0].Decision != webhook.Reply || q.jobs[0].DeliveryID != "d-1" {
		t.Errorf("job = %+v", q.jobs[0])
	}
}

func TestWebhook_RejectsBadSignature(t *testing.T) {
	// Arrange
	q := &fakeQueue{}
	h := newHandler(q)
	req := signedRequest(pendingMsg)
	req.Header.Set("X-Chatwoot-Signature", "sha256=00")

	// Act
	code := do(h, req)

	// Assert
	if code != http.StatusUnauthorized || len(q.jobs) != 0 {
		t.Errorf("code=%d jobs=%d", code, len(q.jobs))
	}
}

func TestWebhook_DropsDuplicateDelivery(t *testing.T) {
	// Arrange
	q := &fakeQueue{}
	h := newHandler(q)

	// Act
	first := do(h, signedRequest(pendingMsg))
	second := do(h, signedRequest(pendingMsg))

	// Assert
	if first != http.StatusAccepted || second != http.StatusOK || len(q.jobs) != 1 {
		t.Errorf("first=%d second=%d jobs=%d", first, second, len(q.jobs))
	}
}

func TestWebhook_IgnoredEventReturnsOK(t *testing.T) {
	// Arrange
	q := &fakeQueue{}
	h := newHandler(q)
	body := strings.Replace(pendingMsg, `"private":false`, `"private":true`, 1)

	// Act
	code := do(h, signedRequest(body))

	// Assert
	if code != http.StatusOK || len(q.jobs) != 0 {
		t.Errorf("code=%d jobs=%d", code, len(q.jobs))
	}
}

func TestWebhook_QueueFullReturns429AndAllowsRetry(t *testing.T) {
	// Arrange
	q := &fakeQueue{err: bot.ErrQueueFull}
	h := newHandler(q)

	// Act
	busy := do(h, signedRequest(pendingMsg))
	q.err = nil
	retry := do(h, signedRequest(pendingMsg))

	// Assert
	if busy != http.StatusTooManyRequests || retry != http.StatusAccepted || len(q.jobs) != 1 {
		t.Errorf("busy=%d retry=%d jobs=%d", busy, retry, len(q.jobs))
	}
}

func TestWebhook_InvalidJSON(t *testing.T) {
	// Arrange
	h := newHandler(&fakeQueue{})

	// Act
	code := do(h, signedRequest(`{not json`))

	// Assert
	if code != http.StatusBadRequest {
		t.Errorf("code=%d", code)
	}
}

func TestHealthz(t *testing.T) {
	// Arrange
	h := newHandler(&fakeQueue{})

	// Act
	code := do(h, httptest.NewRequest(http.MethodGet, "/healthz", nil))

	// Assert
	if code != http.StatusOK {
		t.Errorf("code=%d", code)
	}
}
