package bot

import (
	"context"
	"errors"
	"sync"
	"testing"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/trace"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/webhook"
)

type fakeTracer struct {
	mu    sync.Mutex
	turns []trace.Turn
}

func (f *fakeTracer) Record(t trace.Turn) {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.turns = append(f.turns, t)
}

func tracedBot(l *fakeLLM) (*Bot, *fakeChatwoot, *fakeTracer) {
	cw := &fakeChatwoot{}
	b, _ := newBot(cw, l)
	tr := &fakeTracer{}
	b.opts.Tracer = tr
	b.opts.Knowledge = &recordingRetriever{}
	b.opts.Rewriter = fakeRewriter{out: []string{"ราคาคอร์ส", "course price"}}
	return b, cw, tr
}

func TestTrace_ReplyRecordsAllSteps(t *testing.T) {
	// Arrange
	b, _, tr := tracedBot(&fakeLLM{reply: "3,900 บาทค่ะ"})
	job := customerMsg("ราคาเท่าไหร่")
	job.Event.Sender = webhook.Sender{ID: 9, Type: "contact"}
	job.Event.Inbox.ID = 3

	// Act
	b.Process(context.Background(), job)

	// Assert
	if len(tr.turns) != 1 {
		t.Fatalf("turns = %d, want 1", len(tr.turns))
	}
	got := tr.turns[0]
	if got.Outcome != "replied" || got.Input != "ราคาเท่าไหร่" || got.Output != "3,900 บาทค่ะ" {
		t.Errorf("turn = %+v", got)
	}
	if got.AccountID != 1 || got.InboxID != 3 || got.ConversationID != 7 || got.ContactID != 9 {
		t.Errorf("ids = %d/%d/%d/%d", got.AccountID, got.InboxID, got.ConversationID, got.ContactID)
	}
	if got.Rewrite == nil || got.Rewrite.Output != "ราคาคอร์ส\ncourse price" {
		t.Errorf("rewrite step = %+v", got.Rewrite)
	}
	if got.Search == nil || got.Search.Output == "" || got.Generation == nil || got.Generation.Model != "m" {
		t.Errorf("search/generation = %+v / %+v", got.Search, got.Generation)
	}
	if got.End.Before(got.Start) || got.Generation.End.Before(got.Generation.Start) {
		t.Error("times out of order")
	}
}

func TestTrace_HandoffOutcomes(t *testing.T) {
	cases := map[string]struct {
		job     func() Job
		llm     *fakeLLM
		outcome string
		gen     bool
	}{
		"keyword": {func() Job { return customerMsg("I want a human") }, &fakeLLM{reply: "x"}, "handoff:" + ReasonCustomerAsked, false},
		"file only": {func() Job {
			j := customerMsg("")
			j.Decision = webhook.HandOff
			j.Event.Attachments = []webhook.Attachment{{FileType: "image"}}
			return j
		}, &fakeLLM{reply: "x"}, "handoff:" + ReasonAttachment, false},
		"model asks":  {func() Job { return customerMsg("โอนแล้ว") }, &fakeLLM{reply: HandoffMarker + " staff"}, "handoff:" + ReasonAIRequest, true},
		"model error": {func() Job { return customerMsg("hi") }, &fakeLLM{err: errors.New("down")}, "handoff:" + ReasonLLMError, true},
	}
	for name, c := range cases {
		t.Run(name, func(t *testing.T) {
			// Arrange
			b, _, tr := tracedBot(c.llm)

			// Act
			b.Process(context.Background(), c.job())

			// Assert
			if len(tr.turns) != 1 || tr.turns[0].Outcome != c.outcome {
				t.Fatalf("turns = %+v, want outcome %s", tr.turns, c.outcome)
			}
			if (tr.turns[0].Generation != nil) != c.gen {
				t.Errorf("generation recorded = %v, want %v", tr.turns[0].Generation != nil, c.gen)
			}
		})
	}
}

func TestTrace_ModelErrorIsMarked(t *testing.T) {
	// Arrange
	b, _, tr := tracedBot(&fakeLLM{err: errors.New("down")})

	// Act
	b.Process(context.Background(), customerMsg("hi"))

	// Assert
	if g := tr.turns[0].Generation; g == nil || g.Err == "" {
		t.Errorf("generation = %+v, want the error recorded", g)
	}
}

func TestTrace_RecordedAgentMessagesAreNotTraced(t *testing.T) {
	// Arrange
	b, _, tr := tracedBot(&fakeLLM{reply: "x"})
	job := customerMsg("staff reply")
	job.Decision = webhook.Record

	// Act
	b.Process(context.Background(), job)

	// Assert
	if len(tr.turns) != 0 {
		t.Errorf("turns = %d, want 0 (nothing the AI did)", len(tr.turns))
	}
}
