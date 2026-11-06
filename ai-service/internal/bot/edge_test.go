package bot

import (
	"context"
	"strings"
	"testing"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/webhook"
)

func TestProcess_AttachmentOnlyHandsOffWithoutTheModel(t *testing.T) {
	// Arrange
	cw, l := &fakeChatwoot{}, &fakeLLM{reply: "unused"}
	b, _ := newBot(cw, l)
	b.opts.AttachmentMessage = "got your file"
	job := customerMsg("")
	job.Decision = webhook.HandOff
	job.Event.Attachments = []webhook.Attachment{{FileType: "image"}}

	// Act
	b.Process(context.Background(), job)

	// Assert
	want := "msg:got your file | note:" + ReasonAttachment + " | handoff"
	if got := cw.joined(); got != want {
		t.Errorf("calls = %s, want %s", got, want)
	}
	if l.got != nil {
		t.Error("the model must not be called for a file it cannot read")
	}
}

func TestProcess_TextWithAttachmentTellsTheModel(t *testing.T) {
	// Arrange
	cw, l := &fakeChatwoot{}, &fakeLLM{reply: "ok"}
	b, h := newBot(cw, l)
	job := customerMsg("โอนแล้วค่ะ")
	job.Event.Attachments = []webhook.Attachment{{FileType: "image"}}

	// Act
	b.Process(context.Background(), job)

	// Assert
	turns := h.Get(1, 7)
	if !strings.Contains(turns[0].Content, "โอนแล้วค่ะ") || !strings.Contains(turns[0].Content, "attached 1 file: image") {
		t.Errorf("history = %q, want the text plus the attachment note", turns[0].Content)
	}
}

func TestProcess_LongMessageIsCut(t *testing.T) {
	// Arrange
	cw, l := &fakeChatwoot{}, &fakeLLM{reply: "ok"}
	b, h := newBot(cw, l)

	// Act
	b.Process(context.Background(), customerMsg(strings.Repeat("ก", MaxInputRunes+500)))

	// Assert
	got := []rune(h.Get(1, 7)[0].Content)
	if len(got) > MaxInputRunes+40 || !strings.HasSuffix(string(got), cutMarker) {
		t.Errorf("stored %d runes, want about %d ending with the cut marker", len(got), MaxInputRunes)
	}
}

func TestProcess_ModelAsksForHandoff(t *testing.T) {
	// Arrange
	cw, l := &fakeChatwoot{}, &fakeLLM{reply: HandoffMarker + " แอดมินจะตรวจสอบสลิปให้นะคะ"}
	b, h := newBot(cw, l)

	// Act
	b.Process(context.Background(), customerMsg("โอนแล้วค่ะ ช่วยเช็คให้หน่อย"))

	// Assert
	want := "typing:on | msg:แอดมินจะตรวจสอบสลิปให้นะคะ | note:" + ReasonAIRequest + " | handoff | typing:off"
	if got := cw.joined(); got != want {
		t.Errorf("calls = %s, want %s", got, want)
	}
	if turns := h.Get(1, 7); strings.Contains(turns[len(turns)-1].Content, HandoffMarker) {
		t.Error("the marker must not be stored in history")
	}
}

func TestProcess_MarkerOnlyUsesTheHandoffMessage(t *testing.T) {
	// Arrange
	cw, l := &fakeChatwoot{}, &fakeLLM{reply: "  " + HandoffMarker + "\n"}
	b, _ := newBot(cw, l)

	// Act
	b.Process(context.Background(), customerMsg("ของยังไม่ได้เลย"))

	// Assert
	if got := cw.joined(); !strings.Contains(got, "msg:connecting you | note:"+ReasonAIRequest) {
		t.Errorf("calls = %s, want the default handoff message", got)
	}
}

func TestSplitHandoff(t *testing.T) {
	cases := map[string]struct {
		in, text string
		want     bool
	}{
		"plain":           {"ราคา 3,900 บาทค่ะ", "ราคา 3,900 บาทค่ะ", false},
		"leading marker":  {HandoffMarker + " ส่งต่อแอดมินนะคะ", "ส่งต่อแอดมินนะคะ", true},
		"trailing marker": {"ส่งต่อแอดมินนะคะ\n" + HandoffMarker, "ส่งต่อแอดมินนะคะ", true},
	}
	for name, c := range cases {
		t.Run(name, func(t *testing.T) {
			// Act
			text, want := SplitHandoff(c.in)

			// Assert
			if text != c.text || want != c.want {
				t.Errorf("SplitHandoff(%q) = %q, %v", c.in, text, want)
			}
		})
	}
}

func TestSystemPromptHasDateAndPolicy(t *testing.T) {
	// Arrange
	cw, l := &fakeChatwoot{}, &fakeLLM{reply: "ok"}
	b, _ := newBot(cw, l)
	bkk := time.FixedZone("Asia/Bangkok", 7*3600)
	b.opts.Location = bkk
	b.opts.Now = func() time.Time { return time.Date(2026, 11, 30, 23, 30, 0, 0, time.UTC) }

	// Act
	b.Process(context.Background(), customerMsg("hi"))

	// Assert: 23:30 UTC on 30 Nov is already 1 December in Bangkok (2569 BE).
	sys := l.got[0].Content
	for _, want := range []string{"SYS", "Tuesday 1 December 2026", "2569", "06:30", HandoffMarker, "contact them", "naming its main product"} {
		if !strings.Contains(sys, want) {
			t.Errorf("system prompt is missing %q:\n%s", want, sys)
		}
	}
	if !strings.HasPrefix(sys, "SYS") {
		t.Error("the configured prompt must come first")
	}
}

func TestProcess_RecordedMessagesAreCutToo(t *testing.T) {
	// Arrange: while a human handles the chat, messages are only recorded.
	cw, l := &fakeChatwoot{}, &fakeLLM{reply: "ok"}
	b, h := newBot(cw, l)
	job := customerMsg(strings.Repeat("ข", MaxInputRunes*3))
	job.Decision = webhook.Record

	// Act
	b.Process(context.Background(), job)

	// Assert
	if got := len([]rune(h.Get(1, 7)[0].Content)); got > MaxInputRunes+40 {
		t.Errorf("recorded %d runes, want at most about %d", got, MaxInputRunes)
	}
}

func TestSplitHandoffNearMisses(t *testing.T) {
	for _, in := range []string{"ok [[handoff]]", "ok [[ HANDOFF ]]", "ok\n[[Handoff]]"} {
		// Act
		text, want := SplitHandoff(in)

		// Assert
		if !want || text != "ok" {
			t.Errorf("SplitHandoff(%q) = %q, %v; want \"ok\", true", in, text, want)
		}
	}
}
