package bot

import (
	"context"
	"log/slog"
	"strings"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/webhook"
)

// Customers on Messenger often send several short messages in a row (or a
// photo, then its caption). Every message is read and remembered at once, but
// the reply waits until the customer has been quiet for Options.ReplyDelay,
// so a burst gets one answer that covers all of it, like a person would give.

type convKey struct{ acct, conv int64 }

// maxBurstTexts bounds what a burst keeps for its trace, so a customer who
// never stops typing cannot grow it without limit (each text is already
// capped at MaxInputRunes).
const maxBurstTexts = 20

// StatusReader reads a conversation's status (chatwoot.Client). Before sending
// a reply that waited, the bot checks staff have not taken the chat.
type StatusReader interface {
	ConversationStatus(ctx context.Context, accountID, conversationID int64) (string, error)
}

// pendingReply is a reply waiting for the customer to stop typing.
type pendingReply struct {
	timer  *time.Timer
	images []string // photos from every message in the burst
	texts  []string // what each message said, for the reply's trace
	seq    uint64   // bumped by each new message; only the latest timer replies
}

// deferReply (re)starts the conversation's wait and keeps its photos.
func (b *Bot) deferReply(log *slog.Logger, ev webhook.Event, deliveryID, text string, images []string) {
	key := convKey{ev.Account.ID, ev.ConversationID()}
	b.mu.Lock()
	defer b.mu.Unlock()
	if b.closed {
		return
	}
	if b.pending == nil {
		b.pending = map[convKey]*pendingReply{}
	}
	p := b.pending[key]
	if p == nil {
		p = &pendingReply{}
		b.pending[key] = p
	} else {
		p.timer.Stop()
	}
	p.images = append(p.images, images...)
	p.texts = append(p.texts, text)
	if len(p.texts) > maxBurstTexts {
		p.texts = p.texts[len(p.texts)-maxBurstTexts:]
	}
	if len(p.images) > maxImages {
		p.images = p.images[len(p.images)-maxImages:]
	}
	p.seq++
	job := Job{Event: ev, Decision: webhook.Reply, DeliveryID: deliveryID, flush: p.seq}
	p.timer = time.AfterFunc(b.opts.ReplyDelay, func() { b.queueWaiting(log, key, job, 0) })
}

// queueWaiting hands a burst's reply to its worker. It holds b.mu so Close
// cannot close the queue in between; a full queue is retried a few times
// (the webhook was already accepted, so Chatwoot will not resend it).
func (b *Bot) queueWaiting(log *slog.Logger, key convKey, job Job, try int) {
	b.mu.Lock()
	defer b.mu.Unlock()
	p := b.pending[key]
	if b.closed || p == nil || p.seq != job.flush {
		return
	}
	err := b.Enqueue(job)
	if err == nil {
		return
	}
	if try < 3 {
		p.timer = time.AfterFunc(time.Second, func() { b.queueWaiting(log, key, job, try+1) })
		return
	}
	log.Warn("waiting reply dropped: queue full", "error", err)
	delete(b.pending, key)
}

// takePending returns the burst's photos and texts if seq is still the latest wait.
func (b *Bot) takePending(acct, conv int64, seq uint64) ([]string, []string, bool) {
	b.mu.Lock()
	defer b.mu.Unlock()
	p := b.pending[convKey{acct, conv}]
	if p == nil || p.seq != seq {
		return nil, nil, false
	}
	delete(b.pending, convKey{acct, conv})
	return p.images, p.texts, true
}

// cancelPending drops a waiting reply: staff stepped in, the chat was
// resolved or handed off.
func (b *Bot) cancelPending(acct, conv int64) {
	b.mu.Lock()
	defer b.mu.Unlock()
	if p := b.pending[convKey{acct, conv}]; p != nil {
		p.timer.Stop()
		delete(b.pending, convKey{acct, conv})
	}
}

// flush answers a burst once the customer has gone quiet.
func (b *Bot) flush(ctx context.Context, log *slog.Logger, j Job) {
	ev := j.Event
	acct, conv := ev.Account.ID, ev.ConversationID()
	images, texts, ok := b.takePending(acct, conv, j.flush)
	if !ok {
		return // a newer message restarted the wait, or staff took over
	}
	if sr, ok := b.opts.Chatwoot.(StatusReader); ok {
		status, err := sr.ConversationStatus(ctx, acct, conv)
		switch {
		case err != nil:
			// Same risk as replying at once, which is what the bot did before
			// replies waited; the webhook Pause still covers most takeovers.
			log.Warn("conversation status check failed, replying", "error", err)
		case status != "pending":
			log.Info("waiting reply dropped: staff have the chat", "status", status)
			return
		}
	}
	tr := b.startTurn(ev, strings.Join(texts, "\n"))
	defer b.finishTurn(tr)
	b.reply(ctx, log, acct, ev.Inbox.ID, conv, tr, images)
}
