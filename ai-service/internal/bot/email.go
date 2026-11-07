package bot

import (
	"context"
	"log/slog"
	"regexp"
	"strings"
)

// AttributeSetter saves custom attributes on a Chatwoot conversation
// (chatwoot.Client). An Agent Bot token cannot edit contacts, so a
// customer's email is kept on the conversation, where staff can filter by it.
type AttributeSetter interface {
	SetConversationAttributes(ctx context.Context, accountID, conversationID int64, attrs map[string]string) error
}

// EmailAttribute is the conversation attribute that holds the email a
// customer gave in chat, so staff can match buyers by email.
const EmailAttribute = "customer_email"

var emailPattern = regexp.MustCompile(`(?i)\b[a-z0-9._%+-]+@[a-z0-9-]+(?:\.[a-z0-9-]+)*\.[a-z]{2,}\b`)

// customerEmail is the last email address in a message, lower-cased, or "".
func customerEmail(text string) string {
	all := emailPattern.FindAllString(text, -1)
	if len(all) == 0 {
		return ""
	}
	e := strings.ToLower(all[len(all)-1])
	if len(e) > 254 {
		return ""
	}
	return e
}

// saveEmail stores an email the customer sent on the conversation. It never
// logs the address, and a failure does not stop the reply.
func (b *Bot) saveEmail(ctx context.Context, log *slog.Logger, acct, conv int64, text string) {
	email := customerEmail(text)
	setter, ok := b.opts.Chatwoot.(AttributeSetter)
	if email == "" || !ok {
		return
	}
	if err := setter.SetConversationAttributes(ctx, acct, conv, map[string]string{EmailAttribute: email}); err != nil {
		log.Warn("customer email not saved", "error", err)
		return
	}
	log.Info("customer email saved", "attribute", EmailAttribute)
}
