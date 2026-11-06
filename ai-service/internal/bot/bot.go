// Package bot turns classified Chatwoot events into replies or handoffs.
package bot

import (
	"context"
	"errors"
	"hash/fnv"
	"log/slog"
	"strconv"
	"sync"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/handoff"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/llm"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/memory"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/webhook"
)

// Chatwoot is the subset of the Chatwoot client the bot needs.
type Chatwoot interface {
	SendMessage(ctx context.Context, accountID, conversationID int64, content string) error
	SendPrivateNote(ctx context.Context, accountID, conversationID int64, content string) error
	Handoff(ctx context.Context, accountID, conversationID int64) error
	SetTyping(ctx context.Context, accountID, conversationID int64, on bool) error
}

// Completer is the subset of the LLM client the bot needs.
type Completer interface {
	Complete(ctx context.Context, messages []llm.Message) (llm.Result, error)
}

// Handoff reasons, written to a private note so agents see why the bot stepped back.
const (
	ReasonCustomerAsked = "ai-handoff:customer-request"
	ReasonLLMError      = "ai-handoff:llm-error"
)

// Options configures a Bot.
type Options struct {
	Chatwoot       Chatwoot
	LLM            Completer
	History        *memory.History
	Handoff        *handoff.Detector
	SystemPrompt   string
	HandoffMessage string
	FailureMessage string
	Logger         *slog.Logger
	Timeout        time.Duration // per-event processing budget
}

// Job is one event to process plus its delivery id for log correlation.
type Job struct {
	Event      webhook.Event
	Decision   webhook.Decision
	DeliveryID string
}

// Bot processes jobs on a fixed pool of workers. Jobs for the same
// conversation always go to the same worker so replies stay in order.
type Bot struct {
	opts   Options
	queues []chan Job
	wg     sync.WaitGroup
}

// New creates a Bot with `workers` workers, each with a buffer of queueSize/workers.
func New(opts Options, workers, queueSize int) *Bot {
	if opts.Logger == nil {
		opts.Logger = slog.Default()
	}
	if opts.Timeout == 0 {
		opts.Timeout = 2 * time.Minute
	}
	per := max(queueSize/workers, 1)
	b := &Bot{opts: opts, queues: make([]chan Job, workers)}
	for i := range b.queues {
		b.queues[i] = make(chan Job, per)
	}
	return b
}

// ErrQueueFull means the job was not accepted; the caller should ask
// Chatwoot to retry (HTTP 429).
var ErrQueueFull = errors.New("queue full")

// Enqueue hands a job to its conversation's worker without blocking.
func (b *Bot) Enqueue(j Job) error {
	q := b.queues[b.shard(j.Event.Account.ID, j.Event.ConversationID())]
	select {
	case q <- j:
		return nil
	default:
		return ErrQueueFull
	}
}

// Start launches the workers. They stop when ctx is cancelled or Close is called.
func (b *Bot) Start(ctx context.Context) {
	for _, q := range b.queues {
		b.wg.Add(1)
		go func(q chan Job) {
			defer b.wg.Done()
			for {
				select {
				case <-ctx.Done():
					return
				case j, ok := <-q:
					if !ok {
						return
					}
					b.Process(ctx, j)
				}
			}
		}(q)
	}
}

// Close stops accepting work, drains queued jobs and waits for workers.
func (b *Bot) Close() {
	for _, q := range b.queues {
		close(q)
	}
	b.wg.Wait()
}

func (b *Bot) shard(account, conversation int64) int {
	h := fnv.New32a()
	h.Write([]byte(strconv.FormatInt(account, 10) + ":" + strconv.FormatInt(conversation, 10)))
	return int(h.Sum32() % uint32(len(b.queues)))
}

// Process handles one job synchronously. Exported for tests.
func (b *Bot) Process(parent context.Context, j Job) {
	ev := j.Event
	acct, conv := ev.Account.ID, ev.ConversationID()
	log := b.opts.Logger.With(
		"delivery_id", j.DeliveryID, "account_id", acct, "inbox_id", ev.Inbox.ID,
		"conversation_id", conv, "message_id", ev.ID,
	)
	ctx, cancel := context.WithTimeout(parent, b.opts.Timeout)
	defer cancel()

	switch j.Decision {
	case webhook.Forget:
		b.opts.History.Forget(acct, conv)
		log.Debug("conversation resolved, history cleared")
	case webhook.Record:
		role := "user"
		if ev.MessageType == "outgoing" {
			role = "assistant"
		}
		b.opts.History.Append(acct, conv, memory.Turn{Role: role, Content: ev.Content})
	case webhook.Reply:
		b.opts.History.Append(acct, conv, memory.Turn{Role: "user", Content: ev.Content})
		if b.opts.Handoff.Wants(ev.Content) {
			b.handoff(ctx, log, acct, conv, b.opts.HandoffMessage, ReasonCustomerAsked)
			return
		}
		b.reply(ctx, log, acct, conv)
	}
}

func (b *Bot) reply(ctx context.Context, log *slog.Logger, acct, conv int64) {
	cw := b.opts.Chatwoot
	if err := cw.SetTyping(ctx, acct, conv, true); err != nil {
		log.Warn("typing on failed", "error", err)
	}
	defer func() {
		// Use a fresh context so typing is cleared even after a timeout.
		offCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		if err := cw.SetTyping(offCtx, acct, conv, false); err != nil {
			log.Warn("typing off failed", "error", err)
		}
	}()

	messages := []llm.Message{{Role: "system", Content: b.opts.SystemPrompt}}
	for _, t := range b.opts.History.Get(acct, conv) {
		messages = append(messages, llm.Message{Role: t.Role, Content: t.Content})
	}

	started := time.Now()
	res, err := b.opts.LLM.Complete(ctx, messages)
	latency := time.Since(started)
	if err != nil {
		log.Error("llm completion failed", "error", err, "latency_ms", latency.Milliseconds())
		b.handoff(ctx, log, acct, conv, b.opts.FailureMessage, ReasonLLMError)
		return
	}

	if err := cw.SendMessage(ctx, acct, conv, res.Content); err != nil {
		log.Error("send reply failed", "error", err)
		return
	}
	b.opts.History.Append(acct, conv, memory.Turn{Role: "assistant", Content: res.Content})
	// Content is not logged (personal data); lengths and usage are enough for cost tracking.
	log.Info("ai replied",
		"model", res.Model,
		"prompt_tokens", res.PromptTokens,
		"completion_tokens", res.CompletionTokens,
		"latency_ms", latency.Milliseconds(),
		"history_turns", len(messages)-1,
		"reply_chars", len([]rune(res.Content)),
	)
}

func (b *Bot) handoff(ctx context.Context, log *slog.Logger, acct, conv int64, customerMsg, reason string) {
	cw := b.opts.Chatwoot
	if customerMsg != "" {
		if err := cw.SendMessage(ctx, acct, conv, customerMsg); err != nil {
			log.Error("send handoff message failed", "error", err)
		}
	}
	if err := cw.SendPrivateNote(ctx, acct, conv, reason); err != nil {
		log.Warn("handoff note failed", "error", err)
	}
	if err := cw.Handoff(ctx, acct, conv); err != nil {
		log.Error("handoff failed", "error", err, "reason", reason)
		return
	}
	log.Info("handed off to human", "reason", reason)
}
