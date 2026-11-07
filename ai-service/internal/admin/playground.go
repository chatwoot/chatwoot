package admin

import (
	"context"
	"math"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/bot"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/memory"
)

// Tester runs the bot's reply pipeline without Chatwoot (bot.Bot.Preview).
type Tester interface {
	Preview(ctx context.Context, acct, inbox int64, history []memory.Turn) bot.Preview
}

const (
	maxTestTurns = 12   // earlier turns are dropped, like a short chat
	maxTestRunes = 2000 // per message
)

type testSource struct {
	Title string
	Score string
}

type testData struct {
	AccountID int64
	Inbox     string
	Enabled   bool
	Turns     []memory.Turn
	Asked     string // the latest test question, for "add this answer"
	Handoff   bool
	Reason    string
	Sources   []testSource
	Model     string
	LatencyMS int64
	Error     string
	Knowledge bool
}

var reasonText = map[string]string{
	bot.ReasonCustomerAsked: "The message asks for a person, so the bot passes the chat to staff without answering.",
	bot.ReasonAIRequest:     "The AI decided staff should answer this one, and passes the chat to staff.",
	bot.ReasonLLMError:      "The AI model failed. Check the AI providers page. Customers would get the failure message and staff would take over.",
}

func (h *Handler) showTest(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	h.renderPage(w, http.StatusOK, "test.html", testData{
		AccountID: accountParam(q.Get("account")), Inbox: q.Get("inbox"),
		Enabled: h.Tester != nil, Knowledge: h.Knowledge != nil,
	})
}

// submitTest answers one test message. The conversation so far travels in
// hidden form fields, so nothing is stored on the server, and nothing is
// sent to Chatwoot, kept in chat memory or traced.
func (h *Handler) submitTest(w http.ResponseWriter, r *http.Request) {
	r.Body = http.MaxBytesReader(w, r.Body, 256<<10)
	if err := r.ParseForm(); err != nil {
		http.Error(w, "form too large or invalid", http.StatusBadRequest)
		return
	}
	acct := accountParam(r.PostForm.Get("account"))
	d := testData{AccountID: acct, Inbox: r.PostForm.Get("inbox"), Enabled: h.Tester != nil, Knowledge: h.Knowledge != nil}
	d.Turns = historyFromForm(r.PostForm["role"], r.PostForm["text"])
	if !d.Enabled {
		h.renderPage(w, http.StatusServiceUnavailable, "test.html", d)
		return
	}
	inbox, err := inboxParam(d.Inbox)
	msg := clip(strings.TrimSpace(r.PostForm.Get("message")))
	switch {
	case err != nil:
		d.Error = err.Error()
	case msg == "":
		d.Error = "Type a message to send."
	}
	if d.Error != "" {
		h.renderPage(w, http.StatusUnprocessableEntity, "test.html", d)
		return
	}

	d.Turns = trimTurns(append(d.Turns, memory.Turn{Role: "user", Content: msg}))
	started := time.Now()
	p := h.Tester.Preview(r.Context(), acct, inbox, d.Turns)
	d.LatencyMS = time.Since(started).Milliseconds()
	d.Turns = append(d.Turns, memory.Turn{Role: "assistant", Content: p.Reply})
	d.Asked, d.Handoff, d.Reason, d.Model = msg, p.Handoff, reasonText[p.Reason], p.Model
	for _, hit := range p.Sources {
		d.Sources = append(d.Sources, testSource{Title: hit.Title, Score: strconv.Itoa(int(math.Round(hit.Score*100))) + "%"})
	}
	// Metadata only: test messages are business content but may be pasted
	// from real customers, so their text is never logged.
	h.Logger.Info("admin test reply", "account_id", acct, "inbox_id", inbox, "handoff", p.Handoff,
		"reason", p.Reason, "sources", len(p.Sources), "model", p.Model, "latency_ms", d.LatencyMS,
		"turns", len(d.Turns), "failed", p.Err != nil)
	if p.Err != nil {
		h.Logger.Warn("admin test reply failed", "account_id", acct, "error", p.Err)
	}
	h.renderPage(w, http.StatusOK, "test.html", d)
}

// historyFromForm pairs role and text fields, keeping only well-formed turns.
func historyFromForm(roles, texts []string) []memory.Turn {
	var turns []memory.Turn
	for i := 0; i < len(roles) && i < len(texts); i++ {
		role, text := roles[i], clip(strings.TrimSpace(texts[i]))
		if (role != "user" && role != "assistant") || text == "" {
			continue
		}
		turns = append(turns, memory.Turn{Role: role, Content: text})
	}
	return trimTurns(turns)
}

func trimTurns(t []memory.Turn) []memory.Turn {
	if len(t) > maxTestTurns {
		t = t[len(t)-maxTestTurns:]
	}
	return t
}

func clip(s string) string {
	if r := []rune(s); len(r) > maxTestRunes {
		return string(r[:maxTestRunes])
	}
	return s
}
