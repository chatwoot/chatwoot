package trace

import (
	"encoding/json"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"
	"time"
)

func sampleTurn() Turn {
	t0 := time.Date(2026, 11, 7, 3, 0, 0, 0, time.UTC)
	return Turn{
		AccountID: 1, InboxID: 3, ConversationID: 77, ContactID: 9,
		Start: t0, End: t0.Add(3 * time.Second),
		Input:   "ผ่อนได้ไหม เบอร์ 0812345678",
		Output:  "ผ่อน 0% 3 เดือน เดือนละ 1,300 บาทค่ะ",
		Outcome: "replied",
		Rewrite: &Step{Start: t0, End: t0.Add(800 * time.Millisecond), Output: "ผ่อนชำระคอร์ส AutoCut\nAutoCut instalments"},
		Search:  &Step{Start: t0.Add(800 * time.Millisecond), End: t0.Add(time.Second), Output: "วิธีสมัครเรียนและชำระเงิน AutoCut (0.61)"},
		Generation: &Generation{Step: Step{Start: t0.Add(time.Second), End: t0.Add(3 * time.Second)},
			Model: "gpt-6-luna", InputTokens: 1200, OutputTokens: 40},
	}
}

type otlpDoc struct {
	ResourceSpans []struct {
		ScopeSpans []struct {
			Spans []struct {
				TraceID      string `json:"traceId"`
				SpanID       string `json:"spanId"`
				ParentSpanID string `json:"parentSpanId"`
				Name         string `json:"name"`
				Start        string `json:"startTimeUnixNano"`
				End          string `json:"endTimeUnixNano"`
				Attributes   []struct {
					Key   string         `json:"key"`
					Value map[string]any `json:"value"`
				} `json:"attributes"`
			} `json:"spans"`
		} `json:"scopeSpans"`
	} `json:"resourceSpans"`
}

func attrs(t *testing.T, doc otlpDoc, span string) map[string]any {
	t.Helper()
	for _, s := range doc.ResourceSpans[0].ScopeSpans[0].Spans {
		if s.Name == span {
			out := map[string]any{}
			for _, a := range s.Attributes {
				for _, v := range a.Value {
					out[a.Key] = v
				}
			}
			return out
		}
	}
	t.Fatalf("span %q not found", span)
	return nil
}

func TestEncodeBuildsOneTraceWithChildSpans(t *testing.T) {
	// Arrange
	e := &Exporter{Key: []byte("k"), Text: TextRedacted, Environment: "production"}

	// Act
	raw, err := e.encode([]Turn{sampleTurn()})

	// Assert
	if err != nil {
		t.Fatal(err)
	}
	var doc otlpDoc
	if err := json.Unmarshal(raw, &doc); err != nil {
		t.Fatalf("not OTLP JSON: %v\n%s", err, raw)
	}
	spans := doc.ResourceSpans[0].ScopeSpans[0].Spans
	if len(spans) != 4 {
		t.Fatalf("got %d spans, want 4 (turn, rewrite, search, generation)", len(spans))
	}
	root := spans[0]
	if root.Name != "chat-turn" || root.ParentSpanID != "" || len(root.TraceID) != 32 || len(root.SpanID) != 16 {
		t.Errorf("root span = %+v", root)
	}
	for _, s := range spans[1:] {
		if s.TraceID != root.TraceID || s.ParentSpanID != root.SpanID {
			t.Errorf("span %s is not a child of the turn", s.Name)
		}
	}
	if root.Start != "1794020400000000000" {
		t.Errorf("start = %s, want unix nanos as a string", root.Start)
	}
	for _, name := range []string{"chat-turn", "query-rewrite", "knowledge-search", "answer"} {
		a := attrs(t, doc, name)
		if a["langfuse.session.id"] != Pseudonym(e.Key, "conversation", 77) || a["langfuse.user.id"] != Pseudonym(e.Key, "contact", 9) {
			t.Errorf("%s: session/user must be pseudonyms on every span: %v", name, a)
		}
		if a["langfuse.trace.metadata.account_id"] != "1" {
			t.Errorf("%s: account metadata missing", name)
		}
	}
	gen := attrs(t, doc, "answer")
	if gen["langfuse.observation.type"] != "generation" || gen["langfuse.observation.model.name"] != "gpt-6-luna" ||
		!strings.Contains(gen["langfuse.observation.usage_details"].(string), `"input":1200`) {
		t.Errorf("generation attributes = %v", gen)
	}
	if in, _ := gen["langfuse.observation.input"].(string); !strings.Contains(in, "[PHONE]") {
		t.Errorf("generation input must be the redacted customer message, got %q", in)
	}
	turn := attrs(t, doc, "chat-turn")
	if in := turn["langfuse.observation.input"].(string); strings.Contains(in, "0812345678") || !strings.Contains(in, "[PHONE]") {
		t.Errorf("input not redacted: %q", in)
	}
	if turn["langfuse.environment"] != "production" || turn["langfuse.trace.metadata.outcome"] != "replied" {
		t.Errorf("turn attributes = %v", turn)
	}
}

func TestEncodeTextOffSendsNoText(t *testing.T) {
	// Arrange
	e := &Exporter{Key: []byte("k"), Text: TextOff}

	// Act
	raw, _ := e.encode([]Turn{sampleTurn()})

	// Assert
	body := string(raw)
	for _, leaked := range []string{"ผ่อน", "1,300", "AutoCut instalments", "langfuse.observation.input", "langfuse.observation.output"} {
		if strings.Contains(body, leaked) {
			t.Errorf("TRACE_TEXT=off still sent %q", leaked)
		}
	}
	if !strings.Contains(body, "gpt-6-luna") {
		t.Error("numbers and model must still be sent")
	}
}

func TestEncodeNeverSendsRawIDs(t *testing.T) {
	// Arrange
	e := &Exporter{Key: []byte("k"), Text: TextRedacted}
	turn := sampleTurn()
	turn.ConversationID, turn.ContactID = 987654, 123456

	// Act
	raw, _ := e.encode([]Turn{turn})

	// Assert
	if s := string(raw); strings.Contains(s, "987654") || strings.Contains(s, "123456") {
		t.Error("raw conversation or contact id sent")
	}
}

type collector struct {
	mu      sync.Mutex
	bodies  [][]byte
	headers []http.Header
	status  int
}

func (c *collector) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	b, _ := io.ReadAll(r.Body)
	c.mu.Lock()
	c.bodies = append(c.bodies, b)
	c.headers = append(c.headers, r.Header.Clone())
	c.mu.Unlock()
	if c.status != 0 {
		w.WriteHeader(c.status)
	}
}

func (c *collector) count() int {
	c.mu.Lock()
	defer c.mu.Unlock()
	return len(c.bodies)
}

func TestExporterSendsBatchesWithAuthAndFlushesOnClose(t *testing.T) {
	// Arrange
	col := &collector{}
	srv := httptest.NewServer(col)
	defer srv.Close()
	e := NewExporter(Config{BaseURL: srv.URL, PublicKey: "pk-lf-1", SecretKey: "sk-lf-2", Text: TextRedacted,
		FlushEvery: time.Hour, BatchSize: 10}, slog.New(slog.NewJSONHandler(io.Discard, nil)))

	// Act
	e.Record(sampleTurn())
	e.Record(sampleTurn())
	e.Close()

	// Assert
	if col.count() != 1 {
		t.Fatalf("posts = %d, want 1 batch on close", col.count())
	}
	h := col.headers[0]
	user, pass, ok := (&http.Request{Header: h}).BasicAuth()
	if !ok || user != "pk-lf-1" || pass != "sk-lf-2" {
		t.Error("missing Basic auth with the key pair")
	}
	if h.Get("x-langfuse-ingestion-version") != "4" || h.Get("Content-Type") != "application/json" {
		t.Errorf("headers = %v", h)
	}
	var doc otlpDoc
	_ = json.Unmarshal(col.bodies[0], &doc)
	if n := len(doc.ResourceSpans[0].ScopeSpans[0].Spans); n != 8 {
		t.Errorf("spans in batch = %d, want 8", n)
	}
}

func TestExporterNeverBlocksAndSurvivesServerErrors(t *testing.T) {
	// Arrange: a failing backend and a tiny buffer.
	col := &collector{status: http.StatusInternalServerError}
	srv := httptest.NewServer(col)
	defer srv.Close()
	e := NewExporter(Config{BaseURL: srv.URL, PublicKey: "p", SecretKey: "s", Buffer: 2, BatchSize: 1, FlushEvery: time.Hour},
		slog.New(slog.NewJSONHandler(io.Discard, nil)))

	// Act: far more turns than the buffer holds must return immediately.
	done := make(chan struct{})
	go func() {
		for range 500 {
			e.Record(sampleTurn())
		}
		close(done)
	}()

	// Assert
	select {
	case <-done:
	case <-time.After(2 * time.Second):
		t.Fatal("Record blocked")
	}
	e.Close()
	if e.Dropped() == 0 {
		t.Error("a full buffer must drop turns and count them")
	}
}

func TestNilExporterIsANoOp(t *testing.T) {
	// Arrange
	var e *Exporter

	// Act + Assert: tracing off must not need nil checks at call sites.
	e.Record(sampleTurn())
	e.Close()
}
