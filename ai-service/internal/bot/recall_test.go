package bot

import (
	"context"
	"errors"
	"strings"
	"testing"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/memory"
)

type fakeReader struct {
	turns []memory.Turn
	err   error
	calls int
	skip  int64
}

func (f *fakeReader) RecentTurns(_ context.Context, _, _ int64, skipID int64) ([]memory.Turn, error) {
	f.calls++
	f.skip = skipID
	return f.turns, f.err
}

func TestBotRecallsTheChatFromChatwootWhenItHasNoMemory(t *testing.T) {
	// Arrange: the bot restarted (or the chat was closed and reopened).
	cw := &fakeChatwoot{}
	l := &fakeLLM{reply: "ok"}
	b, h := newBot(cw, l)
	r := &fakeReader{turns: []memory.Turn{
		{Role: "user", Content: "อีเมลผม restart.test@gmail.com"},
		{Role: "assistant", Content: "แอดมินบอกว่าจ่ายพรุ่งนี้ได้ครับ"},
	}}
	b.opts.HistoryReader = r

	// Act
	b.Process(context.Background(), customerMsg("ตกลงจ่ายพรุ่งนี้ได้ใช่ไหม"))

	// Assert
	if r.calls != 1 || r.skip != 1 {
		t.Fatalf("reader calls=%d skip=%d, want one call skipping the current message", r.calls, r.skip)
	}
	var sent []string
	for _, m := range l.got {
		sent = append(sent, m.Content)
	}
	all := strings.Join(sent, "\n")
	if !strings.Contains(all, "restart.test@gmail.com") || !strings.Contains(all, "แอดมินบอกว่าจ่ายพรุ่งนี้ได้ครับ") {
		t.Errorf("the model must see the recalled chat, got %q", all)
	}
	if got := h.Get(1, 7); len(got) < 3 {
		t.Errorf("memory should hold the recalled chat plus the new message, got %d turns", len(got))
	}
}

func TestBotDoesNotRecallWhenItRemembers(t *testing.T) {
	// Arrange
	b, h := newBot(&fakeChatwoot{}, &fakeLLM{reply: "ok"})
	r := &fakeReader{}
	b.opts.HistoryReader = r
	h.Append(1, 7, memory.Turn{Role: "user", Content: "ก่อนหน้า"})

	// Act
	b.Process(context.Background(), customerMsg("ต่อ"))

	// Assert
	if r.calls != 0 {
		t.Errorf("reader calls = %d, want 0 while the bot has its own memory (it also holds voice and photo notes)", r.calls)
	}
}

func TestRecallFailureStillReplies(t *testing.T) {
	// Arrange
	cw := &fakeChatwoot{}
	b, _ := newBot(cw, &fakeLLM{reply: "ตอบได้ครับ"})
	b.opts.HistoryReader = &fakeReader{err: errors.New("chatwoot down")}

	// Act
	b.Process(context.Background(), customerMsg("ราคา"))

	// Assert
	if !strings.Contains(cw.joined(), "msg:ตอบได้ครับ") {
		t.Errorf("a failed recall must not stop the reply: %s", cw.joined())
	}
}
