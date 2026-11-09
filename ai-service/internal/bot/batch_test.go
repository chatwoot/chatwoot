package bot

import (
	"context"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/llm"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/profile"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/webhook"
)

// countingLLM counts model calls and keeps the last request.
type countingLLM struct {
	mu    sync.Mutex
	calls int
	got   []llm.Message
	reply string
}

func (c *countingLLM) Complete(_ context.Context, m []llm.Message) (llm.Result, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.calls++
	c.got = m
	return llm.Result{Content: c.reply, Model: "m"}, nil
}

func (c *countingLLM) snapshot() (int, []llm.Message) {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.calls, c.got
}

func batchingBot(t *testing.T, delay time.Duration) (*Bot, *fakeChatwoot, *countingLLM) {
	t.Helper()
	cw := &fakeChatwoot{}
	b, _ := newBot(cw, &fakeLLM{})
	l := &countingLLM{reply: "ตอบรวมครับ"}
	b.opts.LLM, b.opts.ReplyDelay = l, delay
	ctx, cancel := context.WithCancel(context.Background())
	b.Start(ctx)
	t.Cleanup(cancel)
	return b, cw, l
}

func msgN(id int64, text string) Job {
	j := customerMsg(text)
	j.Event.ID = id
	return j
}

func waitFor(t *testing.T, cond func() bool) {
	t.Helper()
	for i := 0; i < 100; i++ {
		if cond() {
			return
		}
		time.Sleep(10 * time.Millisecond)
	}
}

func TestQuickMessagesGetOneReply(t *testing.T) {
	// Arrange
	b, cw, l := batchingBot(t, 80*time.Millisecond)

	// Act: three messages inside the wait, like a customer typing fast.
	for i, text := range []string{"สวัสดีครับ", "ใช้กับ Windows ได้ไหม", "ราคาเท่าไหร่"} {
		_ = b.Enqueue(msgN(int64(i+1), text))
		time.Sleep(20 * time.Millisecond)
	}
	waitFor(t, func() bool { n, _ := l.snapshot(); return n > 0 })
	time.Sleep(150 * time.Millisecond)

	// Assert
	calls, got := l.snapshot()
	if calls != 1 {
		t.Fatalf("model calls = %d, want 1 for a burst", calls)
	}
	var history []string
	for _, m := range got {
		history = append(history, m.Content)
	}
	joined := strings.Join(history, "\n")
	for _, want := range []string{"สวัสดีครับ", "ใช้กับ Windows ได้ไหม", "ราคาเท่าไหร่"} {
		if !strings.Contains(joined, want) {
			t.Errorf("the one reply must see %q", want)
		}
	}
	if n := strings.Count(cw.joined(), "msg:"); n != 1 {
		t.Errorf("messages sent = %d, want 1: %s", n, cw.joined())
	}
}

func TestBurstKeepsPhotosFromEarlierMessages(t *testing.T) {
	// Arrange: Messenger sends a slip photo and its caption as two messages.
	b, _, _, _ := mediaBot(profile.Features{Images: true}, &fakeLLM{})
	l := &countingLLM{reply: "เห็นสลิปครับ"}
	b.opts.LLM, b.opts.ReplyDelay = l, 80*time.Millisecond
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	b.Start(ctx)

	// Act
	_ = b.Enqueue(fileJob("", photo))
	time.Sleep(20 * time.Millisecond)
	_ = b.Enqueue(msgN(2, "โอนแล้วครับ"))
	waitFor(t, func() bool { n, _ := l.snapshot(); return n > 0 })

	// Assert
	_, got := l.snapshot()
	last := got[len(got)-1]
	if len(last.Images) != 1 {
		t.Fatalf("the reply must still see the photo from the first message, images = %d", len(last.Images))
	}
}

func TestStaffReplyCancelsAWaitingReply(t *testing.T) {
	// Arrange
	b, cw, l := batchingBot(t, 100*time.Millisecond)
	staff := Job{Decision: webhook.Record, Event: webhook.Event{
		Event: "message_created", ID: 9, Content: "แอดมินดูแลเองครับ", MessageType: "outgoing",
		Account: webhook.Account{ID: 1}, Conversation: webhook.Conversation{ID: 7, Status: "open"},
		Sender: webhook.Sender{Type: "user"},
	}}

	// Act
	_ = b.Enqueue(msgN(1, "ราคาเท่าไหร่"))
	time.Sleep(20 * time.Millisecond)
	_ = b.Enqueue(staff)
	time.Sleep(250 * time.Millisecond)

	// Assert
	if calls, _ := l.snapshot(); calls != 0 || strings.Contains(cw.joined(), "msg:") {
		t.Fatalf("bot answered after staff stepped in: calls=%d %s", calls, cw.joined())
	}
}

func TestAskingForAPersonIsNotDelayed(t *testing.T) {
	// Arrange
	b, cw, _ := batchingBot(t, time.Hour)

	// Act
	_ = b.Enqueue(msgN(1, "human please"))
	waitFor(t, func() bool { return strings.Contains(cw.joined(), "handoff") })

	// Assert
	if !strings.Contains(cw.joined(), "msg:connecting you") {
		t.Fatalf("a request for a person must hand off at once: %s", cw.joined())
	}
}

// statusChatwoot reports a conversation status, like Chatwoot's GET conversation.
type statusChatwoot struct {
	*fakeChatwoot
	status string
}

func (s statusChatwoot) ConversationStatus(context.Context, int64, int64) (string, error) {
	return s.status, nil
}

func TestWaitingReplyChecksTheChatIsStillTheBots(t *testing.T) {
	// Arrange: staff assigned the chat to themselves without typing.
	b, cw, l := batchingBot(t, 60*time.Millisecond)
	b.opts.Chatwoot = statusChatwoot{fakeChatwoot: cw, status: "open"}

	// Act
	_ = b.Enqueue(msgN(1, "ราคาเท่าไหร่"))
	time.Sleep(250 * time.Millisecond)

	// Assert
	if calls, _ := l.snapshot(); calls != 0 || strings.Contains(cw.joined(), "msg:") {
		t.Fatalf("bot answered a chat staff own: calls=%d %s", calls, cw.joined())
	}
}

func TestPauseCancelsAWaitingReply(t *testing.T) {
	// Arrange
	b, cw, l := batchingBot(t, 100*time.Millisecond)
	pause := Job{Decision: webhook.Pause, Event: webhook.Event{
		Event: "conversation_status_changed", Status: "open",
		Account: webhook.Account{ID: 1}, Conversation: webhook.Conversation{ID: 7},
	}}
	pause.Event.ID = 7

	// Act
	_ = b.Enqueue(msgN(1, "ราคาเท่าไหร่"))
	time.Sleep(20 * time.Millisecond)
	_ = b.Enqueue(pause)
	time.Sleep(250 * time.Millisecond)

	// Assert
	if calls, _ := l.snapshot(); calls != 0 || strings.Contains(cw.joined(), "msg:") {
		t.Fatalf("bot answered after staff took the chat: calls=%d %s", calls, cw.joined())
	}
}

func TestBurstIsOneTraceWithEveryMessage(t *testing.T) {
	// Arrange
	b, _, tracer := tracedBot(&fakeLLM{reply: "ตอบรวมครับ"})
	b.opts.ReplyDelay = 60 * time.Millisecond
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	b.Start(ctx)

	// Act
	_ = b.Enqueue(msgN(1, "ใช้ Windows ได้ไหม"))
	time.Sleep(15 * time.Millisecond)
	_ = b.Enqueue(msgN(2, "ราคาเท่าไหร่"))
	waitFor(t, func() bool { tracer.mu.Lock(); defer tracer.mu.Unlock(); return len(tracer.turns) > 0 })
	time.Sleep(100 * time.Millisecond)

	// Assert
	tracer.mu.Lock()
	defer tracer.mu.Unlock()
	if len(tracer.turns) != 1 {
		t.Fatalf("traces = %d, want 1 for the burst", len(tracer.turns))
	}
	in := tracer.turns[0].Input
	if !strings.Contains(in, "ใช้ Windows ได้ไหม") || !strings.Contains(in, "ราคาเท่าไหร่") || tracer.turns[0].Outcome != "replied" {
		t.Errorf("trace = %+v, want both messages and a reply", tracer.turns[0])
	}
}

func TestEndlessBurstKeepsABoundedTrace(t *testing.T) {
	// Arrange
	b, _, _ := batchingBot(t, time.Hour)
	log := b.opts.Logger

	// Act
	for i := 0; i < maxBurstTexts+15; i++ {
		b.deferReply(log, msgN(int64(i+1), "spam").Event, "", "spam", nil)
	}

	// Assert
	b.mu.Lock()
	defer b.mu.Unlock()
	p := b.pending[convKey{1, 7}]
	if p == nil || len(p.texts) != maxBurstTexts {
		t.Fatalf("texts kept = %v, want %d", p, maxBurstTexts)
	}
	p.timer.Stop()
}

func TestCloseDuringAWaitingReplyDoesNotCrash(t *testing.T) {
	// Arrange: a reply is waiting when the service shuts down (a deploy).
	cw := &fakeChatwoot{}
	b, _ := newBot(cw, &fakeLLM{reply: "x"})
	b.opts.ReplyDelay = 30 * time.Millisecond
	b.Start(context.Background())
	_ = b.Enqueue(msgN(1, "ราคา"))
	time.Sleep(10 * time.Millisecond)

	// Act
	b.Close()
	time.Sleep(80 * time.Millisecond) // past the wait: the timer must not send on a closed queue

	// Assert: reaching here without a panic is the test; nothing is sent after close.
	if strings.Contains(cw.joined(), "msg:") {
		t.Errorf("no reply may be sent after Close: %s", cw.joined())
	}
}

func TestInstantReplyDoesNotCancelTheWaitingReply(t *testing.T) {
	// Arrange: the page's auto-greeting echo arrives while the bot waits.
	b, cw, l := batchingBot(t, 80*time.Millisecond)
	greeting := Job{Decision: webhook.Record, Event: webhook.Event{
		Event: "message_created", ID: 9, Content: "ขอบคุณที่ติดต่อมา", MessageType: "outgoing",
		Account: webhook.Account{ID: 1}, Conversation: webhook.Conversation{ID: 7, Status: "pending"},
	}}
	greeting.Event.ContentAttributes.ExternalEcho = true

	// Act
	_ = b.Enqueue(msgN(1, "สนใจคอร์ส"))
	time.Sleep(20 * time.Millisecond)
	_ = b.Enqueue(greeting)
	waitFor(t, func() bool { n, _ := l.snapshot(); return n > 0 })

	// Assert
	if calls, _ := l.snapshot(); calls != 1 || !strings.Contains(cw.joined(), "msg:ตอบรวมครับ") {
		t.Fatalf("the bot must still answer the customer: calls=%d %s", calls, cw.joined())
	}
}
