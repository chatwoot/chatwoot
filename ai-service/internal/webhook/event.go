// Package webhook parses, verifies and filters Chatwoot Agent Bot webhooks.
//
// Payload shape verified against Chatwoot source (commit 656c814):
// app/models/message.rb#webhook_data and
// app/presenters/conversations/event_data_presenter.rb#webhook_data.
package webhook

import (
	"encoding/json"
	"strings"
)

// Event is the subset of an Agent Bot webhook payload that ai-service uses.
// Message events carry message fields at the top level; conversation events
// (conversation_resolved, ...) carry conversation fields at the top level.
type Event struct {
	Event        string       `json:"event"`
	ID           int64        `json:"id"` // message id (message events) or conversation display id
	Content      string       `json:"content"`
	MessageType  string       `json:"message_type"` // incoming | outgoing | activity | template
	Private      bool         `json:"private"`
	Status       string       `json:"status"` // conversation events only
	Account      Account      `json:"account"`
	Inbox        Inbox        `json:"inbox"`
	Sender       Sender       `json:"sender"`
	Conversation Conversation `json:"conversation"`
}

// Account identifies the Chatwoot account.
type Account struct {
	ID int64 `json:"id"`
}

// Inbox identifies the Chatwoot inbox (channel).
type Inbox struct {
	ID int64 `json:"id"`
}

// Sender is the message author. Type is "contact", "user" or "agent_bot".
type Sender struct {
	ID   int64  `json:"id"`
	Type string `json:"type"`
}

// Conversation is the conversation a message belongs to.
// ID is the display id used in REST API paths.
type Conversation struct {
	ID     int64  `json:"id"`
	Status string `json:"status"` // open | resolved | pending | snoozed
}

// Parse decodes a webhook body.
func Parse(body []byte) (Event, error) {
	var ev Event
	err := json.Unmarshal(body, &ev)
	return ev, err
}

// Decision says what to do with an event.
type Decision int

const (
	// Ignore means no action.
	Ignore Decision = iota
	// Reply means the bot should answer this customer message.
	Reply
	// Record means remember the message as context but do not answer
	// (e.g. a human agent's public reply).
	Record
	// Forget means drop stored state for the conversation (resolved).
	Forget
)

// Classify decides how to handle an event. It answers only public customer
// messages in pending conversations, which prevents loops on the bot's own
// replies, private notes and conversations a human has taken over.
func Classify(ev Event) Decision {
	switch ev.Event {
	case "conversation_resolved":
		return Forget
	case "message_created":
	default:
		return Ignore
	}
	if ev.Private || strings.TrimSpace(ev.Content) == "" {
		return Ignore
	}
	switch ev.MessageType {
	case "incoming":
		if ev.Conversation.Status != "pending" {
			return Record
		}
		return Reply
	case "outgoing":
		if ev.Sender.Type == "agent_bot" {
			return Ignore // already recorded when we sent it
		}
		return Record
	default:
		return Ignore
	}
}

// ConversationID returns the conversation display id for any event type.
func (ev Event) ConversationID() int64 {
	if ev.Event == "message_created" || ev.Event == "message_updated" {
		return ev.Conversation.ID
	}
	return ev.ID
}
