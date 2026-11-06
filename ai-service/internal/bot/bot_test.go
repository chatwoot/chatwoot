package bot

import (
	"context"
	"errors"
	"io"
	"log/slog"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/handoff"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/llm"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/memory"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/webhook"
)

type fakeChatwoot struct {
	mu    sync.Mutex
	calls []string
}

func (f *fakeChatwoot) record(s string) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.calls = append(f.calls, s)
	return nil
}
func (f *fakeChatwoot) SendMessage(_ context.Context, _, _ int64, c string) error {
	return f.record("msg:" + c)
}
func (f *fakeChatwoot) SendPrivateNote(_ context.Context, _, _ int64, c string) error {
	return f.record("note:" + c)
}
func (f *fakeChatwoot) Handoff(context.Context, int64, int64) error { return f.record("handoff") }
func (f *fakeChatwoot) SetTyping(_ context.Context, _, _ int64, on bool) error {
	if on {
		return f.record("typing:on")
	}
	return f.record("typing:off")
}
func (f *fakeChatwoot) joined() string {
	f.mu.Lock()
	defer f.mu.Unlock()
	return strings.Join(f.calls, " | ")
}

type fakeLLM struct {
	got   []llm.Message
	reply string
	err   error
}

func (f *fakeLLM) Complete(_ context.Context, m []llm.Message) (llm.Result, error) {
	f.got = m
	return llm.Result{Content: f.reply, Model: "m"}, f.err
}

func newBot(cw *fakeChatwoot, l *fakeLLM) (*Bot, *memory.History) {
	h := memory.NewHistory(20, time.Hour, nil)
	return New(Options{
		Chatwoot: cw, LLM: l, History: h,
		Handoff:        handoff.New([]string{"human"}),
		SystemPrompt:   "SYS",
		HandoffMessage: "connecting you",
		FailureMessage: "sorry, connecting you",
		Logger:         slog.New(slog.NewJSONHandler(io.Discard, nil)),
	}, 2, 4), h
}

func customerMsg(text string) Job {
	return Job{Decision: webhook.Reply, Event: webhook.Event{
		Event: "message_created", ID: 1, Content: text, MessageType: "incoming",
		Account: webhook.Account{ID: 1}, Conversation: webhook.Conversation{ID: 7, Status: "pending"},
	}}
}

func TestProcess_RepliesWithHistoryAndTyping(t *testing.T) {
	// Arrange
	cw, l := &fakeChatwoot{}, &fakeLLM{reply: "We open at 9."}
	b, h := newBot(cw, l)
	h.Append(1, 7, memory.Turn{Role: "user", Content: "hi"})
	h.Append(1, 7, memory.Turn{Role: "assistant", Content: "hello!"})

	// Act
	b.Process(context.Background(), customerMsg("when do you open?"))

	// Assert
	if got := cw.joined(); got != "typing:on | msg:We open at 9. | typing:off" {
		t.Errorf("calls = %s", got)
	}
	if len(l.got) != 4 || l.got[0].Content != "SYS" || l.got[3].Content != "when do you open?" {
		t.Errorf("llm messages = %+v", l.got)
	}
	if turns := h.Get(1, 7); len(turns) != 4 || turns[3].Role != "assistant" {
		t.Errorf("history = %+v", turns)
	}
}

func TestProcess_CustomerAsksForHuman(t *testing.T) {
	// Arrange
	cw, l := &fakeChatwoot{}, &fakeLLM{reply: "unused"}
	b, _ := newBot(cw, l)

	// Act
	b.Process(context.Background(), customerMsg("I want a HUMAN"))

	// Assert
	want := "msg:connecting you | note:" + ReasonCustomerAsked + " | handoff"
	if got := cw.joined(); got != want {
		t.Errorf("calls = %s, want %s", got, want)
	}
	if l.got != nil {
		t.Error("LLM must not be called on handoff request")
	}
}

func TestProcess_LLMErrorHandsOff(t *testing.T) {
	// Arrange
	cw, l := &fakeChatwoot{}, &fakeLLM{err: errors.New("boom")}
	b, _ := newBot(cw, l)

	// Act
	b.Process(context.Background(), customerMsg("price?"))

	// Assert
	want := "typing:on | msg:sorry, connecting you | note:" + ReasonLLMError + " | handoff | typing:off"
	if got := cw.joined(); got != want {
		t.Errorf("calls = %s, want %s", got, want)
	}
}

func TestProcess_RecordAndForget(t *testing.T) {
	// Arrange
	cw, l := &fakeChatwoot{}, &fakeLLM{}
	b, h := newBot(cw, l)
	agentReply := Job{Decision: webhook.Record, Event: webhook.Event{
		Event: "message_created", Content: "agent here", MessageType: "outgoing",
		Account: webhook.Account{ID: 1}, Conversation: webhook.Conversation{ID: 7},
	}}
	resolved := Job{Decision: webhook.Forget, Event: webhook.Event{
		Event: "conversation_resolved", ID: 7, Account: webhook.Account{ID: 1},
	}}

	// Act
	b.Process(context.Background(), agentReply)
	afterRecord := h.Get(1, 7)
	b.Process(context.Background(), resolved)

	// Assert
	if len(afterRecord) != 1 || afterRecord[0].Role != "assistant" {
		t.Errorf("recorded = %+v", afterRecord)
	}
	if h.Get(1, 7) != nil || cw.joined() != "" {
		t.Errorf("forget failed or unexpected calls: %s", cw.joined())
	}
}

func TestEnqueue_FullQueueRejects(t *testing.T) {
	// Arrange: 2 workers, queue 4 → 2 slots per worker, workers not started.
	b, _ := newBot(&fakeChatwoot{}, &fakeLLM{})
	j := customerMsg("x")

	// Act
	e1, e2, e3 := b.Enqueue(j), b.Enqueue(j), b.Enqueue(j)

	// Assert
	if e1 != nil || e2 != nil || !errors.Is(e3, ErrQueueFull) {
		t.Errorf("errs = %v %v %v", e1, e2, e3)
	}
}

func TestStartClose_DrainsQueuedJobs(t *testing.T) {
	// Arrange
	cw, l := &fakeChatwoot{}, &fakeLLM{reply: "ok"}
	b, _ := newBot(cw, l)
	_ = b.Enqueue(customerMsg("hello"))

	// Act
	b.Start(context.Background())
	b.Close()

	// Assert
	if !strings.Contains(cw.joined(), "msg:ok") {
		t.Errorf("job not processed: %s", cw.joined())
	}
}
