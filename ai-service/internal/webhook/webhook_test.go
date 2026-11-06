package webhook

import (
	"encoding/hex"
	"errors"
	"strconv"
	"testing"
	"time"
)

const samplePayload = `{
  "event": "message_created",
  "id": 42,
  "content": "สวัสดีค่ะ",
  "message_type": "incoming",
  "private": false,
  "account": {"id": 1, "name": "Acme"},
  "inbox": {"id": 3, "name": "LINE"},
  "sender": {"id": 9, "name": "Somchai", "type": "contact"},
  "conversation": {"id": 7, "status": "pending", "inbox_id": 3}
}`

func TestParse_ReadsMessageFields(t *testing.T) {
	// Arrange
	body := []byte(samplePayload)

	// Act
	ev, err := Parse(body)

	// Assert
	if err != nil {
		t.Fatalf("parse: %v", err)
	}
	if ev.ID != 42 || ev.Account.ID != 1 || ev.Conversation.ID != 7 || ev.Conversation.Status != "pending" ||
		ev.MessageType != "incoming" || ev.Sender.Type != "contact" || ev.Content != "สวัสดีค่ะ" {
		t.Errorf("unexpected event: %+v", ev)
	}
	if ev.ConversationID() != 7 {
		t.Errorf("ConversationID = %d", ev.ConversationID())
	}
}

func TestClassify(t *testing.T) {
	base := func() Event {
		ev, _ := Parse([]byte(samplePayload))
		return ev
	}
	cases := []struct {
		name   string
		mutate func(*Event)
		want   Decision
	}{
		{"pending customer message", func(*Event) {}, Reply},
		{"open conversation (human took over)", func(e *Event) { e.Conversation.Status = "open" }, Record},
		{"private note", func(e *Event) { e.Private = true }, Ignore},
		{"empty content, no attachment", func(e *Event) { e.Content = "  " }, Ignore},
		{"attachment only (photo, voice, slip)", func(e *Event) { e.Content = ""; e.Attachments = []Attachment{{FileType: "image"}} }, HandOff},
		{"attachment only, human took over", func(e *Event) {
			e.Content = ""
			e.Attachments = []Attachment{{FileType: "audio"}}
			e.Conversation.Status = "open"
		}, Ignore},
		{"text with attachment", func(e *Event) { e.Attachments = []Attachment{{FileType: "image"}} }, Reply},
		{"bot's own reply", func(e *Event) { e.MessageType = "outgoing"; e.Sender.Type = "agent_bot" }, Ignore},
		{"human agent reply", func(e *Event) { e.MessageType = "outgoing"; e.Sender.Type = "user" }, Record},
		{"activity message", func(e *Event) { e.MessageType = "activity" }, Ignore},
		{"message_updated", func(e *Event) { e.Event = "message_updated" }, Ignore},
		{"conversation resolved", func(e *Event) { e.Event = "conversation_resolved" }, Forget},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			// Arrange
			ev := base()
			tc.mutate(&ev)

			// Act
			got := Classify(ev)

			// Assert
			if got != tc.want {
				t.Errorf("Classify = %v, want %v", got, tc.want)
			}
		})
	}
}

func TestParse_ReadsAttachmentsAndDescribesThem(t *testing.T) {
	// Arrange
	body := []byte(`{"event":"message_created","id":5,"content":"โอนแล้วค่ะ","message_type":"incoming",
		"attachments":[{"id":1,"file_type":"image","data_url":"https://x/y.png"},{"id":2,"file_type":"file"}],
		"account":{"id":1},"inbox":{"id":1},"conversation":{"id":2,"status":"pending"}}`)

	// Act
	ev, err := Parse(body)

	// Assert
	if err != nil || len(ev.Attachments) != 2 || ev.Attachments[0].FileType != "image" {
		t.Fatalf("attachments = %+v, err %v", ev.Attachments, err)
	}
	if got := ev.AttachmentNote(); got != "[The customer attached 2 files: image, file]" {
		t.Errorf("AttachmentNote() = %q", got)
	}
	if (Event{}).AttachmentNote() != "" {
		t.Error("no attachments must give an empty note")
	}
}

func TestConversationID_ForConversationEvent(t *testing.T) {
	// Arrange
	ev := Event{Event: "conversation_resolved", ID: 11}

	// Act
	id := ev.ConversationID()

	// Assert
	if id != 11 {
		t.Errorf("ConversationID = %d, want 11", id)
	}
}

func TestVerify(t *testing.T) {
	now := time.Unix(1_800_000_000, 0)
	body := []byte(samplePayload)
	ts := strconv.FormatInt(now.Unix(), 10)
	valid := "sha256=" + hex.EncodeToString(Sign("s3cret", ts, body))

	cases := []struct {
		name    string
		ts, sig string
		body    []byte
		wantErr error
	}{
		{"valid", ts, valid, body, nil},
		{"missing headers", "", "", body, ErrMissingSignature},
		{"tampered body", ts, valid, []byte(`{"event":"x"}`), ErrBadSignature},
		{"wrong prefix", ts, "md5=abc", body, ErrBadSignature},
		{"not hex", ts, "sha256=zz", body, ErrBadSignature},
		{"stale", strconv.FormatInt(now.Add(-10*time.Minute).Unix(), 10), valid, body, ErrStaleTimestamp},
		{"garbage timestamp", "abc", valid, body, ErrStaleTimestamp},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			// Arrange: inputs in table

			// Act
			err := Verify("s3cret", tc.ts, tc.sig, tc.body, now)

			// Assert
			if !errors.Is(err, tc.wantErr) {
				t.Errorf("Verify err = %v, want %v", err, tc.wantErr)
			}
		})
	}
}
