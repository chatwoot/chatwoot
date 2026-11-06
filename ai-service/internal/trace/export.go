package trace

import (
	"bytes"
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"log/slog"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"
)

// What chat text a trace may carry.
const (
	TextRedacted = "redacted" // customer and bot text, with personal data masked
	TextOff      = "off"      // no chat text at all: timings, model, tokens, outcome only
)

// Step is one timed part of a turn.
type Step struct {
	Start, End time.Time
	Output     string // rewritten queries or retrieved titles; redacted before sending
	Err        string
}

// Generation is the chat-model call that produced the reply.
type Generation struct {
	Step
	Model                     string
	InputTokens, OutputTokens int
	UsedFallback              bool
}

// Turn is everything ai-service did for one customer message.
type Turn struct {
	AccountID, InboxID, ConversationID, ContactID int64
	Start, End                                    time.Time
	Input, Output                                 string // raw; redacted or dropped before sending
	Outcome                                       string // replied | handoff:<reason> | error
	Rewrite, Search                               *Step
	Generation                                    *Generation
}

// Config sets up an Exporter.
type Config struct {
	BaseURL, PublicKey, SecretKey string
	// PseudonymKey hashes ids (see PseudonymKey). Empty: a random per-process
	// key, so ids stay unlinkable but sessions split across restarts.
	PseudonymKey      []byte
	Text              string // TextRedacted (default) or TextOff
	Environment       string
	Buffer, BatchSize int           // defaults 256 and 20
	FlushEvery        time.Duration // default 5s
}

// Exporter sends turns to Langfuse in the background. Record never blocks:
// when the buffer is full the turn is dropped and counted, so tracing can
// never slow down or stop a customer reply. A nil *Exporter does nothing.
type Exporter struct {
	Key         []byte // pseudonym key; never the Langfuse secret key
	Text        string
	Environment string

	endpoint, host string
	auth           string
	client         *http.Client
	logger         *slog.Logger
	batch          int
	every          time.Duration
	queue          chan Turn
	done           chan struct{}
	closeOnce      sync.Once
	dropped        atomic.Int64
}

// NewExporter starts the background sender.
func NewExporter(c Config, logger *slog.Logger) *Exporter {
	base := strings.TrimRight(c.BaseURL, "/")
	e := &Exporter{
		Key: c.PseudonymKey, Text: c.Text, Environment: c.Environment,
		endpoint: base + "/api/public/otel/v1/traces",
		auth:     "Basic " + basic(c.PublicKey, c.SecretKey),
		client:   &http.Client{Timeout: 10 * time.Second},
		logger:   logger,
		batch:    or(c.BatchSize, 20),
		every:    c.FlushEvery,
		queue:    make(chan Turn, or(c.Buffer, 256)),
		done:     make(chan struct{}),
	}
	if u, err := url.Parse(base); err == nil {
		e.host = u.Host
	}
	if len(e.Key) == 0 {
		e.Key = make([]byte, 32)
		_, _ = rand.Read(e.Key)
	}
	if e.every == 0 {
		e.every = 5 * time.Second
	}
	if e.Text != TextOff {
		e.Text = TextRedacted
	}
	go e.loop()
	return e
}

// Record queues a turn; it returns at once.
func (e *Exporter) Record(t Turn) {
	if e == nil {
		return
	}
	select {
	case e.queue <- t:
	default:
		e.dropped.Add(1)
	}
}

// Dropped is how many turns were lost to a full buffer.
func (e *Exporter) Dropped() int64 {
	if e == nil {
		return 0
	}
	return e.dropped.Load()
}

// Close sends what is queued and stops the sender.
func (e *Exporter) Close() {
	if e == nil {
		return
	}
	e.closeOnce.Do(func() {
		close(e.queue)
		<-e.done
	})
}

func (e *Exporter) loop() {
	defer close(e.done)
	tick := time.NewTicker(e.every)
	defer tick.Stop()
	var pending []Turn
	for {
		select {
		case t, ok := <-e.queue:
			if !ok {
				e.send(pending)
				return
			}
			if pending = append(pending, t); len(pending) >= e.batch {
				e.send(pending)
				pending = nil
			}
		case <-tick.C:
			e.send(pending)
			pending = nil
		}
	}
}

func (e *Exporter) send(turns []Turn) {
	if len(turns) == 0 {
		return
	}
	body, err := e.encode(turns)
	if err != nil {
		e.logger.Error("trace encode failed", "error", err)
		return
	}
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, e.endpoint, bytes.NewReader(body))
	if err != nil {
		e.logger.Error("trace request failed", "host", e.host, "error", err)
		return
	}
	req.Header.Set("Authorization", e.auth)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("x-langfuse-ingestion-version", "4")
	res, err := e.client.Do(req)
	if err != nil {
		// Log the host only: the error from net/http carries the full URL.
		e.logger.Warn("trace export failed", "host", e.host, "turns", len(turns))
		return
	}
	res.Body.Close()
	if res.StatusCode >= 300 {
		e.logger.Warn("trace export rejected", "host", e.host, "status", res.StatusCode, "turns", len(turns))
	}
}

// encode turns turns into an OTLP/JSON ExportTraceServiceRequest.
func (e *Exporter) encode(turns []Turn) ([]byte, error) {
	var spans []map[string]any
	for _, t := range turns {
		spans = append(spans, e.turnSpans(t)...)
	}
	return json.Marshal(map[string]any{"resourceSpans": []any{map[string]any{
		"resource": map[string]any{"attributes": kvs(map[string]any{"service.name": "ai-service"})},
		"scopeSpans": []any{map[string]any{
			"scope": map[string]any{"name": "ai-service"},
			"spans": spans,
		}},
	}}})
}

func (e *Exporter) turnSpans(t Turn) []map[string]any {
	traceID, rootID := randHex(16), randHex(8)
	common := map[string]any{
		"langfuse.trace.name":                 "chat-turn",
		"langfuse.session.id":                 Pseudonym(e.Key, "conversation", t.ConversationID),
		"langfuse.user.id":                    Pseudonym(e.Key, "contact", t.ContactID),
		"langfuse.trace.tags":                 []string{"account:" + strconv.FormatInt(t.AccountID, 10)},
		"langfuse.trace.metadata.account_id":  strconv.FormatInt(t.AccountID, 10),
		"langfuse.trace.metadata.inbox_id":    strconv.FormatInt(t.InboxID, 10),
		"langfuse.trace.metadata.outcome":     t.Outcome,
		"langfuse.trace.metadata.text_policy": e.Text,
	}
	if e.Environment != "" {
		common["langfuse.environment"] = e.Environment
	}
	root := merge(common, map[string]any{"langfuse.observation.type": "agent"})
	e.text(root, "langfuse.observation.input", t.Input)
	e.text(root, "langfuse.observation.output", t.Output)
	out := []map[string]any{span(traceID, rootID, "", "chat-turn", t.Start, t.End, root, "")}

	if s := t.Rewrite; s != nil {
		a := merge(common, map[string]any{"langfuse.observation.type": "chain"})
		e.text(a, "langfuse.observation.output", s.Output)
		out = append(out, span(traceID, randHex(8), rootID, "query-rewrite", s.Start, s.End, a, s.Err))
	}
	if s := t.Search; s != nil {
		// Retrieved titles and scores are the business's own content, not personal data.
		a := merge(common, map[string]any{"langfuse.observation.type": "retriever", "langfuse.observation.metadata.hits": s.Output})
		out = append(out, span(traceID, randHex(8), rootID, "knowledge-search", s.Start, s.End, a, s.Err))
	}
	if g := t.Generation; g != nil {
		usage, _ := json.Marshal(map[string]int{"input": g.InputTokens, "output": g.OutputTokens})
		a := merge(common, map[string]any{
			"langfuse.observation.type":                   "generation",
			"langfuse.observation.model.name":             g.Model,
			"langfuse.observation.usage_details":          string(usage),
			"langfuse.observation.metadata.used_fallback": strconv.FormatBool(g.UsedFallback),
		})
		e.text(a, "langfuse.observation.input", t.Input)
		e.text(a, "langfuse.observation.output", t.Output)
		out = append(out, span(traceID, randHex(8), rootID, "answer", g.Start, g.End, a, g.Err))
	}
	return out
}

// text adds chat text only when the policy allows, always redacted.
func (e *Exporter) text(attrs map[string]any, key, value string) {
	if e.Text == TextOff || value == "" {
		return
	}
	attrs[key] = Redact(value)
}

func span(traceID, id, parent, name string, start, end time.Time, attrs map[string]any, errMsg string) map[string]any {
	s := map[string]any{
		"traceId": traceID, "spanId": id, "name": name, "kind": 1,
		"startTimeUnixNano": strconv.FormatInt(start.UnixNano(), 10),
		"endTimeUnixNano":   strconv.FormatInt(end.UnixNano(), 10),
		"attributes":        kvs(attrs),
	}
	if parent != "" {
		s["parentSpanId"] = parent
	}
	if errMsg != "" {
		s["status"] = map[string]any{"code": 2, "message": errMsg}
		s["attributes"] = append(s["attributes"].([]map[string]any),
			kv("langfuse.observation.level", "ERROR"))
	}
	return s
}

func kvs(m map[string]any) []map[string]any {
	out := make([]map[string]any, 0, len(m))
	for k, v := range m {
		out = append(out, kv(k, v))
	}
	return out
}

func kv(key string, v any) map[string]any {
	var val map[string]any
	switch x := v.(type) {
	case []string:
		vals := make([]map[string]any, len(x))
		for i, s := range x {
			vals[i] = map[string]any{"stringValue": s}
		}
		val = map[string]any{"arrayValue": map[string]any{"values": vals}}
	default:
		val = map[string]any{"stringValue": fmt.Sprint(x)}
	}
	return map[string]any{"key": key, "value": val}
}

func merge(a, b map[string]any) map[string]any {
	out := make(map[string]any, len(a)+len(b))
	for k, v := range a {
		out[k] = v
	}
	for k, v := range b {
		out[k] = v
	}
	return out
}

func randHex(n int) string {
	b := make([]byte, n)
	_, _ = rand.Read(b)
	return hex.EncodeToString(b)
}

func basic(user, pass string) string {
	return base64Std(user + ":" + pass)
}

func or(v, def int) int {
	if v > 0 {
		return v
	}
	return def
}
