// Package bot turns classified Chatwoot events into replies or handoffs.
package bot

import (
	"context"
	"errors"
	"fmt"
	"hash/fnv"
	"log/slog"
	"math"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/handoff"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/llm"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/memory"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/profile"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/trace"
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

// Retriever finds knowledge base excerpts for a customer question.
type Retriever interface {
	Retrieve(ctx context.Context, accountID, inboxID int64, queries ...string) ([]knowledge.Hit, error)
}

// Tracer receives what the bot did for one customer message (trace.Exporter).
type Tracer interface {
	Record(t trace.Turn)
}

// Profiles loads an account's business profile (empty when none is saved).
type Profiles interface {
	Get(ctx context.Context, accountID int64) (profile.Profile, error)
}

// Handoff reasons, written to a private note so agents see why the bot stepped back.
const (
	ReasonCustomerAsked = "ai-handoff:customer-request"
	ReasonLLMError      = "ai-handoff:llm-error"
	ReasonAttachment    = "ai-handoff:attachment" // files only; the bot cannot read them
	ReasonAIRequest     = "ai-handoff:ai-request" // the model decided a person is needed
)

// MaxInputRunes caps one customer message before it reaches the model, so a
// huge paste cannot run up the bill. The rest is replaced by cutMarker.
const MaxInputRunes = 2000

const cutMarker = " …[message cut]"

// Options configures a Bot.
type Options struct {
	Chatwoot  Chatwoot
	LLM       Completer
	Knowledge Retriever     // optional; nil answers from the system prompt only
	Profiles  Profiles      // optional; adds each account's business profile to SystemPrompt
	Rewriter  QueryRewriter // optional; adds rewritten (Thai + English) search queries
	Tracer    Tracer        // optional; receives one trace per customer message
	// Media (each optional; a feature also needs its switch on the business profile).
	Fetcher        Fetcher     // downloads attachments from the Chatwoot host
	Transcriber    Transcriber // voice notes → text
	StickerLLM     Completer   // small vision model: is this image a sticker?
	History        *memory.History
	Handoff        *handoff.Detector
	SystemPrompt   string
	HandoffMessage string
	FailureMessage string
	// AttachmentMessage acknowledges files the bot cannot read; "" uses HandoffMessage.
	AttachmentMessage string
	// Now and Location give the model today's date; nil uses time.Now and UTC.
	Now      func() time.Time
	Location *time.Location
	Logger   *slog.Logger
	Timeout  time.Duration // per-event processing budget
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
		b.opts.History.Append(acct, conv, memory.Turn{Role: role, Content: capText(ev.Content)})
	case webhook.HandOff, webhook.Reply:
		tr := b.startTurn(ev, customerText(ev))
		defer b.finishTurn(tr)
		p := profile.Profile{AccountID: acct}
		if len(ev.Attachments) > 0 { // text-only messages skip the extra profile query
			p = b.mediaProfile(ctx, log, acct)
		}
		in, ok := b.readMessage(ctx, log, ev, p, tr)
		if !ok {
			// Only files the bot may not or cannot read: thank and pass to staff.
			b.opts.History.Append(acct, conv, memory.Turn{Role: "user", Content: ev.AttachmentNote()})
			msg := b.opts.AttachmentMessage
			if msg == "" {
				msg = b.opts.HandoffMessage
			}
			tr.Input, tr.Outcome, tr.Output = ev.AttachmentNote(), "handoff:"+ReasonAttachment, msg
			b.handoff(ctx, log, acct, conv, msg, ReasonAttachment)
			return
		}
		tr.Input = in.text
		b.opts.History.Append(acct, conv, memory.Turn{Role: "user", Content: in.text})
		if b.opts.Handoff.Wants(in.text) {
			tr.Outcome, tr.Output = "handoff:"+ReasonCustomerAsked, b.opts.HandoffMessage
			b.handoff(ctx, log, acct, conv, b.opts.HandoffMessage, ReasonCustomerAsked)
			return
		}
		b.reply(ctx, log, acct, ev.Inbox.ID, conv, tr, in.images)
	}
}

// startTurn opens the trace record for one customer message.
func (b *Bot) startTurn(ev webhook.Event, input string) *trace.Turn {
	return &trace.Turn{
		AccountID: ev.Account.ID, InboxID: ev.Inbox.ID, ConversationID: ev.ConversationID(), ContactID: ev.Sender.ID,
		Start: time.Now(), Input: input, Outcome: "error",
	}
}

func (b *Bot) finishTurn(tr *trace.Turn) {
	if b.opts.Tracer == nil {
		return
	}
	tr.End = time.Now()
	b.opts.Tracer.Record(*tr)
}

func (b *Bot) reply(ctx context.Context, log *slog.Logger, acct, inbox, conv int64, tr *trace.Turn, images []string) {
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

	history := b.opts.History.Get(acct, conv)
	started := time.Now()
	res, hits, err := b.answer(ctx, log, acct, inbox, history, tr, images)
	latency := time.Since(started)
	log = log.With(sourceAttrs(hits)...)
	if err != nil {
		log.Error("llm completion failed", "error", err, "latency_ms", latency.Milliseconds())
		tr.Outcome, tr.Output = "handoff:"+ReasonLLMError, b.opts.FailureMessage
		b.handoff(ctx, log, acct, conv, b.opts.FailureMessage, ReasonLLMError)
		return
	}

	text, wantsHuman := SplitHandoff(res.Content)
	tr.Output = text
	if wantsHuman {
		if text == "" {
			text = b.opts.HandoffMessage
		}
		tr.Outcome, tr.Output = "handoff:"+ReasonAIRequest, text
		b.opts.History.Append(acct, conv, memory.Turn{Role: "assistant", Content: text})
		b.handoff(ctx, log, acct, conv, text, ReasonAIRequest)
		return
	}
	if err := cw.SendMessage(ctx, acct, conv, text); err != nil {
		log.Error("send reply failed", "error", err)
		return
	}
	tr.Outcome = "replied"
	b.opts.History.Append(acct, conv, memory.Turn{Role: "assistant", Content: text})
	// Content is not logged (personal data); lengths and usage are enough for cost tracking.
	log.Info("ai replied",
		"model", res.Model,
		"used_fallback", res.UsedFallback,
		"prompt_tokens", res.PromptTokens,
		"completion_tokens", res.CompletionTokens,
		"latency_ms", latency.Milliseconds(),
		"history_turns", len(history),
		"reply_chars", len([]rune(res.Content)),
	)
}

// Answer runs the reply pipeline without Chatwoot: business profile, knowledge
// search (with rewritten queries) and the chat model. answer-eval uses it to
// test exactly what customers get.
func (b *Bot) Answer(ctx context.Context, acct, inbox int64, history []memory.Turn) (llm.Result, []knowledge.Hit, error) {
	return b.answer(ctx, b.opts.Logger.With("account_id", acct), acct, inbox, history, &trace.Turn{}, nil)
}

// answer fills tr's rewrite, search and generation steps as it goes.
// images go with the latest customer message only; history stays text.
func (b *Bot) answer(ctx context.Context, log *slog.Logger, acct, inbox int64, history []memory.Turn, tr *trace.Turn, images []string) (llm.Result, []knowledge.Hit, error) {
	messages := []llm.Message{{Role: "system", Content: b.systemPrompt(ctx, log, acct)}}
	var hits []knowledge.Hit
	if b.opts.Knowledge != nil {
		queries := b.searchQueries(ctx, log, history, tr)
		step := &trace.Step{Start: time.Now()}
		var err error
		hits, err = b.opts.Knowledge.Retrieve(ctx, acct, inbox, queries...)
		step.End, step.Output = time.Now(), hitSummary(hits)
		if err != nil {
			log.Error("knowledge retrieval failed", "error", err)
			step.Err = "knowledge retrieval failed"
		}
		tr.Search = step
		messages = append(messages, llm.Message{Role: "system", Content: knowledgePrompt(hits, err)})
	}
	for _, t := range history {
		messages = append(messages, llm.Message{Role: t.Role, Content: t.Content})
	}
	if last := len(messages) - 1; len(images) > 0 && messages[last].Role == "user" {
		messages[last].Images = images
	}
	gen := &trace.Generation{Step: trace.Step{Start: time.Now()}}
	res, err := b.opts.LLM.Complete(ctx, messages)
	gen.End, gen.Model, gen.UsedFallback = time.Now(), res.Model, res.UsedFallback
	gen.InputTokens, gen.OutputTokens = res.PromptTokens, res.CompletionTokens
	if err != nil {
		gen.Err = "chat model failed"
	}
	tr.Generation = gen
	return res, hits, err
}

// hitSummary lists retrieved titles and scores (business content, no chunk text).
func hitSummary(hits []knowledge.Hit) string {
	lines := make([]string, len(hits))
	for i, h := range hits {
		lines[i] = fmt.Sprintf("%s (%.2f)", h.Title, h.Score)
	}
	return strings.Join(lines, "\n")
}

// searchQueries is the customer's own wording plus, when a rewriter is set,
// a stand-alone Thai and English query. A failed rewrite only loses the extras.
func (b *Bot) searchQueries(ctx context.Context, log *slog.Logger, history []memory.Turn, tr *trace.Turn) []string {
	queries := retrievalQueries(history)
	if b.opts.Rewriter == nil || len(queries) == 0 {
		return queries
	}
	started := time.Now()
	extra, err := b.opts.Rewriter.Rewrite(ctx, history)
	tr.Rewrite = &trace.Step{Start: started, End: time.Now(), Output: strings.Join(extra, "\n")}
	if err != nil {
		tr.Rewrite.Err = "query rewrite failed"
		log.Warn("query rewrite failed", "error", err, "latency_ms", time.Since(started).Milliseconds())
		return queries
	}
	log.Debug("query rewritten", "queries", len(extra), "latency_ms", time.Since(started).Milliseconds())
	return append(queries, extra...)
}

// systemPrompt is the shared prompt plus the account's business profile. If
// the profile cannot be loaded the bot still answers with the shared prompt.
func (b *Bot) systemPrompt(ctx context.Context, log *slog.Logger, acct int64) string {
	prompt := b.opts.SystemPrompt
	if b.opts.Profiles != nil {
		p, err := b.opts.Profiles.Get(ctx, acct)
		if err != nil {
			log.Error("business profile lookup failed", "error", err)
		} else {
			prompt = profile.Prompt(prompt, p)
		}
	}
	return prompt + "\n\n" + policyPrompt(b.now())
}

func (b *Bot) now() time.Time {
	now := time.Now
	if b.opts.Now != nil {
		now = b.opts.Now
	}
	loc := b.opts.Location
	if loc == nil {
		loc = time.UTC
	}
	return now().In(loc)
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

// retrievalQueries searches the latest customer message on its own, plus
// together with the message before it, so a follow-up like "and how much is
// it?" still finds its topic while a new topic is not drowned by the old one.
func retrievalQueries(history []memory.Turn) []string {
	var user []string
	for i := len(history) - 1; i >= 0 && len(user) < 2; i-- {
		if history[i].Role == "user" {
			user = append(user, history[i].Content)
		}
	}
	switch len(user) {
	case 0:
		return nil
	case 1:
		return user
	default:
		return []string{user[0], user[1] + "\n" + user[0]}
	}
}

// knowledgePrompt tells the model which facts it may use.
func knowledgePrompt(hits []knowledge.Hit, err error) string {
	if err != nil {
		return "The knowledge base is unavailable right now. Do not guess facts about the business " +
			"(prices, hours, policies, stock, orders); say you are not sure and offer to connect a staff member."
	}
	if len(hits) == 0 {
		return "The knowledge base has nothing relevant to this question. Do not guess facts about the business " +
			"(prices, hours, policies, stock, orders); say you don't know and offer to connect a staff member."
	}
	var b strings.Builder
	b.WriteString("Knowledge base excerpts. Use them as the only source for facts about the business. " +
		"If they do not answer the question, say you don't know and offer to connect a staff member. " +
		"Do not mention the excerpts or their numbers to the customer.\n")
	for i, h := range hits {
		fmt.Fprintf(&b, "\n[%d] %s\n", i+1, h.Content)
	}
	return b.String()
}

// sourceAttrs records which documents an answer was based on (no content).
func sourceAttrs(hits []knowledge.Hit) []any {
	docs := make([]int64, len(hits))
	chunks := make([]int64, len(hits))
	scores := make([]float64, len(hits))
	for i, h := range hits {
		docs[i], chunks[i] = h.DocumentID, h.ChunkID
		scores[i] = math.Round(h.Score*1000) / 1000
	}
	return []any{"kb_hits", len(hits), "kb_document_ids", docs, "kb_chunk_ids", chunks, "kb_scores", scores}
}

// Preview is what the bot would do with a conversation, worked out without
// Chatwoot: the /admin test page shows it to the owner. Nothing is sent,
// labelled, remembered or traced.
type Preview struct {
	Reply   string
	Handoff bool
	Reason  string // one of the Reason* labels when Handoff is true
	Sources []knowledge.Hit
	Model   string
	Err     error
}

// Preview runs the same decisions as a customer's text message: keyword
// handoff first, then the answer pipeline and the model's handoff marker.
// history ends with the customer's latest message.
func (b *Bot) Preview(parent context.Context, acct, inbox int64, history []memory.Turn) Preview {
	if n := len(history); n > 0 && history[n-1].Role == "user" && b.opts.Handoff.Wants(history[n-1].Content) {
		return Preview{Reply: b.opts.HandoffMessage, Handoff: true, Reason: ReasonCustomerAsked}
	}
	ctx, cancel := context.WithTimeout(parent, b.timeout())
	defer cancel()
	res, hits, err := b.Answer(ctx, acct, inbox, history)
	if err != nil {
		return Preview{Reply: b.opts.FailureMessage, Handoff: true, Reason: ReasonLLMError, Sources: hits, Err: err}
	}
	text, wantsHuman := SplitHandoff(res.Content)
	p := Preview{Reply: text, Sources: hits, Model: res.Model}
	if wantsHuman {
		p.Handoff, p.Reason = true, ReasonAIRequest
		if text == "" {
			p.Reply = b.opts.HandoffMessage
		}
	}
	return p
}

func (b *Bot) timeout() time.Duration {
	if b.opts.Timeout > 0 {
		return b.opts.Timeout
	}
	return time.Minute
}
