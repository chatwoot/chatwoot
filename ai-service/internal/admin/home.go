package admin

import (
	"net/http"
	"strconv"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/profile"
)

// step is one item of the Home setup checklist.
type step struct {
	Title, Hint, Link, Action string
	Done                      bool
}

type homeData struct {
	AccountID   int64
	Steps       []step
	Left        int // required steps not done yet
	Model       string
	Fallback    bool
	Documents   int
	DocsKnown   bool // the knowledge base could be read
	LastUpdated string
	Business    string
	Features    profile.Features
	Profiles    bool
}

// showHome is the first screen: what is set up, what is missing, and a link
// to fix each missing step, so the owner never has to guess what to do next.
func (h *Handler) showHome(w http.ResponseWriter, r *http.Request) {
	acct := accountParam(r.URL.Query().Get("account"))
	cur := h.Store.Get()
	d := homeData{AccountID: acct, Model: cur.Primary.Model, Fallback: cur.Fallback.Configured(), Profiles: h.Profiles != nil}

	if h.Profiles != nil {
		p, err := h.Profiles.Get(r.Context(), acct)
		if err != nil {
			h.Logger.Warn("home: business profile lookup failed", "account_id", acct, "error", err)
		}
		d.Business, d.Features = p.BusinessName, p.Features
	}
	if h.Knowledge != nil {
		docs, err := h.Knowledge.List(r.Context(), acct)
		if err != nil {
			h.Logger.Warn("home: knowledge list failed", "account_id", acct, "error", err)
		} else {
			d.DocsKnown, d.Documents = true, len(docs)
			var last time.Time
			for _, doc := range docs {
				if doc.UpdatedAt.After(last) {
					last = doc.UpdatedAt
				}
			}
			if !last.IsZero() {
				d.LastUpdated = last.Format("2 Jan 2006")
			}
		}
	}

	acctQ := "?account=" + strconv.FormatInt(acct, 10)
	d.Steps = []step{
		{Title: "Connect an AI model", Hint: "The model that writes replies.", Link: "/admin/providers", Action: "Set up", Done: cur.Primary.Configured()},
		{Title: "Turn on knowledge search", Hint: "An embeddings model, so the bot can search your documents.", Link: "/admin/providers", Action: "Set up", Done: cur.Embedding.Configured()},
		{Title: "Describe your business", Hint: "Name, what you sell, tone and rules.", Link: "/admin/business" + acctQ, Action: "Edit profile", Done: d.Business != ""},
		{Title: "Add knowledge", Hint: "Prices, schedules, policies and FAQs the bot may quote.", Link: "/admin/knowledge" + acctQ, Action: "Add knowledge", Done: d.Documents > 0},
	}
	for _, s := range d.Steps {
		if !s.Done {
			d.Left++
		}
	}
	h.renderPage(w, http.StatusOK, "home.html", d)
}
