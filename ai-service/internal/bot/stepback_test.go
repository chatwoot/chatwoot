package bot

import (
	"context"
	"strings"
	"testing"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/memory"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/webhook"
)

// staffReply is an outgoing public message from someone other than the bot:
// an admin in Chatwoot, or a Facebook echo of an admin replying in Messenger
// (Chatwoot stores those with no sender).
func staffReply(status, senderType string, files bool) Job {
	ev := webhook.Event{
		Event: "message_created", ID: 30, Content: "แอดมินตอบเองครับ", MessageType: "outgoing",
		Account: webhook.Account{ID: 1}, Conversation: webhook.Conversation{ID: 7, Status: status},
		Sender: webhook.Sender{Type: senderType},
	}
	if files {
		ev.Content = ""
		ev.Attachments = []webhook.Attachment{{FileType: "image"}}
	}
	if senderType == "" { // Chatwoot stores a Messenger reply as an echo with no sender
		ev.ContentAttributes.ExternalEcho = true
	}
	return Job{Event: ev, Decision: webhook.Classify(ev)}
}

func TestBotStepsBackWhenAnAdminRepliesOutsideChatwoot(t *testing.T) {
	cases := map[string]Job{
		"messenger echo (no sender)": staffReply("pending", "", false),
		"staff typed in chatwoot":    staffReply("pending", "user", false),
		"messenger echo of a photo":  staffReply("pending", "", true),
	}
	for name, job := range cases {
		t.Run(name, func(t *testing.T) {
			// Arrange
			cw := &fakeChatwoot{}
			b, h := newBot(cw, &fakeLLM{reply: "x"})
			h.Append(1, 7, memory.Turn{Role: "user", Content: "ราคาเท่าไหร่"})
			h.Append(1, 7, memory.Turn{Role: "assistant", Content: "3,900 บาทครับ"})

			// Act
			b.Process(context.Background(), job)

			// Assert
			got := cw.joined()
			if strings.Contains(got, "msg:") {
				t.Errorf("the customer must not get a message: %s", got)
			}
			if !strings.Contains(got, "note:🤖 "+reasonLabels[ReasonStaffReplied]+"\n"+ReasonStaffReplied+" | handoff") {
				t.Errorf("want a staff note and the chat moved to staff, got %s", got)
			}
		})
	}
}

func TestStaffReplyOnAStaffChatChangesNothing(t *testing.T) {
	// Arrange
	cw := &fakeChatwoot{}
	b, h := newBot(cw, &fakeLLM{reply: "x"})

	// Act
	b.Process(context.Background(), staffReply("open", "user", false))

	// Assert
	if got := cw.joined(); got != "" {
		t.Errorf("no calls expected on a chat staff already own, got %s", got)
	}
	if turns := h.Get(1, 7); len(turns) != 1 || turns[0].Role != "assistant" {
		t.Errorf("the staff reply should still be remembered as context: %+v", turns)
	}
}

func TestAutomatedMessagesDoNotSwitchTheBotOff(t *testing.T) {
	cases := map[string]func(*memory.History) Job{
		// Facebook Instant Reply arrives as an echo before the bot has said anything.
		"page instant reply before the bot spoke": func(*memory.History) Job { return staffReply("pending", "", false) },
		// A Chatwoot automation message has no sender and is not an echo.
		"chatwoot automation message": func(h *memory.History) Job {
			h.Append(1, 7, memory.Turn{Role: "assistant", Content: "สวัสดีครับ"})
			j := staffReply("pending", "", false)
			j.Event.ContentAttributes.ExternalEcho = false
			return j
		},
		// Messenger echoing the bot's own reply back.
		"echo of the bot's own last reply": func(h *memory.History) Job {
			h.Append(1, 7, memory.Turn{Role: "assistant", Content: "แอดมินตอบเองครับ"})
			return staffReply("pending", "", false)
		},
	}
	for name, build := range cases {
		t.Run(name, func(t *testing.T) {
			// Arrange
			cw := &fakeChatwoot{}
			b, h := newBot(cw, &fakeLLM{reply: "x"})
			job := build(h)

			// Act
			b.Process(context.Background(), job)

			// Assert
			if got := cw.joined(); strings.Contains(got, "handoff") {
				t.Errorf("the bot must keep the chat, got %s", got)
			}
		})
	}
}

func TestTwoPageMessagesBeforeTheBotSpeaksDoNotSwitchItOff(t *testing.T) {
	// Arrange: a Click-to-Messenger ad's welcome message arrives as an echo,
	// then the page's Instant Reply arrives as a second echo. The bot has not
	// said anything yet, so neither is an admin taking over.
	cw := &fakeChatwoot{}
	b, _ := newBot(cw, &fakeLLM{reply: "x"})
	welcome := staffReply("pending", "", false)
	welcome.Event.Content = "สวัสดีค่ะ สนใจคอร์ส AutoCut ไหมคะ"
	instant := staffReply("pending", "", false)
	instant.Event.ID, instant.Event.Content = 31, "ขอบคุณที่ทักมานะคะ"

	// Act
	b.Process(context.Background(), welcome)
	b.Process(context.Background(), instant)

	// Assert
	if got := cw.joined(); strings.Contains(got, "handoff") {
		t.Errorf("the bot must keep the chat, got %s", got)
	}
}

func TestAdminEchoAfterAPageMessageAndABotReplyStillStepsBack(t *testing.T) {
	// Arrange: Instant Reply (page), then the bot answered, then an admin replies.
	cw := &fakeChatwoot{}
	b, h := newBot(cw, &fakeLLM{reply: "x"})
	instant := staffReply("pending", "", false)
	instant.Event.Content = "ขอบคุณที่ทักมานะคะ"
	b.Process(context.Background(), instant)
	h.Append(1, 7, memory.Turn{Role: "assistant", Content: "3,900 บาทครับ"})
	admin := staffReply("pending", "", false)
	admin.Event.ID = 32

	// Act
	b.Process(context.Background(), admin)

	// Assert
	if got := cw.joined(); !strings.Contains(got, "handoff") {
		t.Errorf("an admin reply after the bot spoke must hand off, got %s", got)
	}
}
