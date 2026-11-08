package admin

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"strings"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/pending"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/profile"
)

// Approver applies or drops an AI-app edit waiting for approval (#60). The
// MCP server implements it with the same checks and history as its tools.
type Approver interface {
	Approve(ctx context.Context, accountID, id int64, version int, approver string) error
	Reject(ctx context.Context, accountID, id int64, version int, approver string) error
}

type approvalsData struct {
	Enabled bool
	Account int64
	Items   []approvalItem
	Done    string // "approved" or "rejected" after a decision
	Error   string
}

type approvalItem struct {
	ID      int64
	Version int
	Heading string
	From    string
	When    string
	New     bool // a document that does not exist yet
	Fields  []fieldDiff
}

type fieldDiff struct {
	Label, Current, Proposed string
}

var profileLabels = []struct{ key, label string }{
	{"business_name", "Business name"}, {"about", "What the business does"}, {"tone", "Tone and style"}, {"rules", "Rules"},
}

func (h *Handler) approvalsOn() bool { return h.Pending != nil && h.Approver != nil }

func (h *Handler) showApprovals(w http.ResponseWriter, r *http.Request) {
	acct := accountParam(r.URL.Query().Get("account"))
	data := approvalsData{Account: acct}
	if d := r.URL.Query().Get("done"); d == "approved" || d == "rejected" {
		data.Done = d
	}
	h.renderApprovals(w, r, http.StatusOK, data)
}

func (h *Handler) submitApprovals(w http.ResponseWriter, r *http.Request) {
	if !h.approvalsOn() {
		http.Error(w, "approvals are off: they need DATABASE_URL and MCP_ENABLED", http.StatusServiceUnavailable)
		return
	}
	if err := r.ParseForm(); err != nil {
		http.Error(w, "invalid form", http.StatusBadRequest)
		return
	}
	f := r.PostForm
	acct, err1 := strconv.ParseInt(strings.TrimSpace(f.Get("account")), 10, 64)
	id, err2 := strconv.ParseInt(f.Get("id"), 10, 64)
	version, err3 := strconv.Atoi(f.Get("version"))
	decision := f.Get("decision")
	if err1 != nil || err2 != nil || err3 != nil || acct < 1 || id < 1 || version < 1 || (decision != "approve" && decision != "reject") {
		http.Error(w, "account, id, version and decision (approve or reject) are required", http.StatusBadRequest)
		return
	}
	decide := h.Approver.Approve
	if decision == "reject" {
		decide = h.Approver.Reject
	}
	err := decide(context.WithoutCancel(r.Context()), acct, id, version, actor(r))
	switch {
	case err == nil:
		h.Logger.Info("ai change "+decision+"d", "account_id", acct, "change_id", id)
		http.Redirect(w, r, "/admin/approvals?account="+strconv.FormatInt(acct, 10)+"&done="+decision+"d", http.StatusSeeOther)
	case errors.Is(err, pending.ErrChanged):
		h.renderApprovals(w, r, http.StatusConflict, approvalsData{Account: acct,
			Error: "The app changed this after you opened it. Nothing was applied; check the new version below."})
	case errors.Is(err, pending.ErrNotFound):
		h.renderApprovals(w, r, http.StatusNotFound, approvalsData{Account: acct,
			Error: "That change is no longer waiting. It may have been approved or rejected already."})
	default:
		h.Logger.Error("ai change "+decision+" failed", "account_id", acct, "change_id", id, "error", err)
		h.renderApprovals(w, r, http.StatusUnprocessableEntity, approvalsData{Account: acct,
			Error: "Not applied. The change still waits; try again, and check the service logs if it keeps failing."})
	}
}

func (h *Handler) renderApprovals(w http.ResponseWriter, r *http.Request, status int, data approvalsData) {
	data.Enabled = h.approvalsOn()
	if data.Enabled {
		items, err := h.approvalItems(r.Context(), data.Account)
		if err != nil {
			h.Logger.Error("load ai changes", "account_id", data.Account, "error", err)
			data.Error = "Could not load the waiting changes. Check the database connection."
		}
		data.Items = items
	}
	h.renderPage(w, r, status, "approvals.html", data)
}

// approvalItems shows each waiting change next to what customers see now.
func (h *Handler) approvalItems(ctx context.Context, acct int64) ([]approvalItem, error) {
	changes, err := h.Pending.List(ctx, acct)
	if err != nil {
		return nil, err
	}
	items := make([]approvalItem, 0, len(changes))
	for _, c := range changes {
		it := approvalItem{ID: c.ID, Version: c.Version, From: c.Actor, When: c.At.In(h.loc()).Format("2006-01-02 15:04")}
		switch c.Kind {
		case pending.KindProfile:
			it.Heading = "Business profile"
			it.Fields, err = h.profileDiff(ctx, acct, c.Proposed)
		case pending.KindDocument:
			it.Heading, it.New, it.Fields, err = h.documentDiff(ctx, acct, c.Target, c.Proposed)
		}
		if err != nil {
			return nil, err
		}
		items = append(items, it)
	}
	return items, nil
}

func (h *Handler) profileDiff(ctx context.Context, acct int64, raw []byte) ([]fieldDiff, error) {
	var proposed map[string]string
	if err := json.Unmarshal(raw, &proposed); err != nil {
		return nil, err
	}
	cur := profile.Profile{}
	if h.Profiles != nil {
		var err error
		if cur, err = h.Profiles.Get(ctx, acct); err != nil {
			return nil, err
		}
	}
	now := map[string]string{"business_name": cur.BusinessName, "about": cur.About, "tone": cur.Tone, "rules": cur.Rules}
	var out []fieldDiff
	for _, f := range profileLabels {
		if v, ok := proposed[f.key]; ok {
			out = append(out, fieldDiff{Label: f.label, Current: now[f.key], Proposed: v})
		}
	}
	return out, nil
}

func (h *Handler) documentDiff(ctx context.Context, acct int64, key string, raw []byte) (string, bool, []fieldDiff, error) {
	var d struct {
		Kind      string `json:"kind"`
		InboxID   int64  `json:"inbox_id"`
		Title     string `json:"title"`
		Content   string `json:"content"`
		StartDate string `json:"start_date"`
		LastDay   string `json:"last_day"`
	}
	if err := json.Unmarshal(raw, &d); err != nil {
		return "", false, nil, err
	}
	var cur knowledge.Document
	isNew := false
	if h.Knowledge != nil {
		var err error
		cur, err = h.Knowledge.GetByKey(ctx, acct, key)
		switch {
		case errors.Is(err, knowledge.ErrNotFound):
			isNew = true
		case err != nil:
			return "", false, nil, err
		}
	}
	fields := []fieldDiff{{Label: "Title", Current: cur.Title, Proposed: d.Title}, {Label: "Text", Current: cur.Content, Proposed: d.Content}}
	// Everything the approval applies is shown: where it is used, and the
	// kind of a new document (an existing one keeps its kind).
	usedIn := fieldDiff{Label: "Used in", Proposed: inboxLabel(d.InboxID)}
	if !isNew && h.Knowledge != nil {
		usedIn.Current = inboxLabel(cur.InboxID)
	}
	fields = append(fields, usedIn)
	if isNew {
		kind := "Text"
		if d.Kind == "faq" {
			kind = "FAQ (question and answer)"
		}
		fields = append(fields, fieldDiff{Label: "Kind", Proposed: kind})
	}
	if d.StartDate != "" || d.LastDay != "" {
		fields = append(fields, fieldDiff{Label: "Dates", Proposed: "from " + orNow(d.StartDate) + " to " + orNoEnd(d.LastDay)})
	}
	return "Knowledge: " + key, isNew, fields, nil
}

func orNow(s string) string {
	if s == "" {
		return "now"
	}
	return s
}

func orNoEnd(s string) string {
	if s == "" {
		return "no end"
	}
	return s
}

func inboxLabel(id int64) string {
	if id > 0 {
		return "Only inbox " + strconv.FormatInt(id, 10)
	}
	return "All inboxes"
}
