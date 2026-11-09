package admin

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"path/filepath"
	"slices"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/pdftext"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/webfetch"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/websync"
)

// maxUpload bounds a knowledge form post: a PDF of up to pdftext.MaxBytes
// plus the form fields. Text files stay limited to maxTextUpload.
const (
	maxUpload     = pdftext.MaxBytes + 1<<20
	maxTextUpload = 2 << 20
)

// allowedUploads are the file types read as plain UTF-8 text.
var allowedUploads = map[string]bool{".txt": true, ".md": true, ".markdown": true}

type docView struct {
	ID       int64
	Kind     string
	Title    string
	Inbox    string
	Chunks   int
	Stale    int
	Updated  string
	Preview  string
	Status   string // active, scheduled, expired
	Window   string // "Until 31 Dec 2026", "From 1 Dec 2026", ""
	Used     string // "12 times, last 5 Nov 2026" or "Not used yet"
	Unused   bool
	Disabled bool
}

// docForm is the add or edit form's values, kept when a post is re-shown.
type docForm struct {
	ID                   int64 // set when editing
	Synced               bool  // kept in sync from a website or data file
	Kind                 string
	InboxID              string
	Question, Answer     string
	DocTitle, DocContent string
	From, Until          string // yyyy-mm-dd; Until is the last day the bot may use it
}

type pageView struct {
	Feed     bool
	Items    int
	ID       int64
	Interval int
	URL      string
	Title    string
	Status   string // ok, error, gone, new
	Label    string
	Detail   string
	Checked  string
}

type dupView struct {
	DocumentID int64
	Title      string
	Score      string
}

type knowledgeData struct {
	Enabled   bool // a database is configured
	Embedding string
	AccountID int64
	Docs      []docView
	Stale     int
	Notice    string
	Error     string
	ErrorForm string // which form the error belongs to: faq, doc, edit, list
	Show      string // list filter: "", "unused", "inactive"
	Total     int
	Unused    int
	Inactive  int
	docForm   // re-filled add form values
	Edit      *docForm
	Dupes     []dupView // similar existing documents found before adding
	WebOn     bool
	Pages     []pageView
	PageURL   string
	PageKind  string // "page" or "feed", kept when adding fails
	DupeForm  string // faq or doc
}

func (h *Handler) showKnowledge(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	data := knowledgeData{AccountID: accountParam(q.Get("account")), Show: listFilter(q.Get("show"))}
	data.Notice = noticeFor(q)
	if id, err := strconv.ParseInt(q.Get("edit"), 10, 64); err == nil && id > 0 && h.Knowledge != nil {
		d, err := h.Knowledge.Get(r.Context(), data.AccountID, id)
		if err != nil {
			data.Error, data.ErrorForm = "That document no longer exists.", "list"
		} else {
			f := h.formFromDoc(d)
			data.Edit = &f
		}
	}
	h.renderKnowledge(w, r, http.StatusOK, data)
}

func listFilter(v string) string {
	if v == "unused" || v == "inactive" {
		return v
	}
	return ""
}

func (h *Handler) renderKnowledge(w http.ResponseWriter, r *http.Request, status int, data knowledgeData) {
	if h.Knowledge != nil {
		data.Enabled = true
		data.Embedding = h.Knowledge.Embedder.Model()
		docs, err := h.Knowledge.List(r.Context(), data.AccountID)
		if err != nil {
			h.Logger.Error("list knowledge", "account_id", data.AccountID, "error", err)
			if data.Error == "" {
				data.Error, data.ErrorForm = "Could not load the knowledge base. Check the database connection.", "list"
			}
		}
		now := time.Now()
		for _, d := range docs {
			v := h.toDocView(d, now)
			data.Total++
			data.Stale += d.StaleChunks
			if v.Unused {
				data.Unused++
			}
			if v.Status != knowledge.StatusActive {
				data.Inactive++
			}
			if (data.Show == "unused" && !v.Unused) || (data.Show == "inactive" && v.Status == knowledge.StatusActive) {
				continue
			}
			data.Docs = append(data.Docs, v)
		}
	}
	if h.Web != nil {
		data.WebOn = true
		pages, err := h.Web.List(r.Context(), data.AccountID)
		if err != nil {
			h.Logger.Error("list web pages", "account_id", data.AccountID, "error", err)
		}
		for _, p := range pages {
			v := pageView{ID: p.ID, Interval: p.IntervalHours, URL: p.URL, Title: p.Title, Status: p.Status, Checked: "Not yet",
				Feed: p.IsFeed(), Items: p.Items}
			if !p.CheckedAt.IsZero() {
				v.Checked = h.when(p.CheckedAt)
			}
			switch p.Status {
			case "ok":
				v.Label = "In sync"
				var parts []string
				if p.IsFeed() {
					parts = append(parts, strconv.Itoa(p.Items)+" rows")
				}
				if !p.ChangedAt.IsZero() {
					parts = append(parts, "changed "+h.day(p.ChangedAt))
				}
				if p.Error != "" { // a feed with skipped rows
					parts = append(parts, p.Error)
				}
				v.Detail = strings.Join(parts, " · ")
			case "error":
				v.Label, v.Detail = "Problem", p.Error
			case "gone":
				v.Label, v.Detail = "Page gone", "hidden from the bot; deleted a week after it disappeared"
				if p.IsFeed() {
					v.Label = "File gone"
				}
			default:
				v.Label = "Waiting"
				if p.IsFeed() {
					v.Label = "Reading…"
				}
			}
			data.Pages = append(data.Pages, v)
		}
	}
	h.renderPage(w, r, status, "knowledge.html", data)
}

func (h *Handler) loc() *time.Location {
	if h.Location != nil {
		return h.Location
	}
	return time.UTC
}

func (h *Handler) day(t time.Time) string { return t.In(h.loc()).Format("2 Jan 2006") }

// when is the one date-and-time format of every admin page.
func (h *Handler) when(t time.Time) string { return t.In(h.loc()).Format("2 Jan 2006, 15:04") }

func (h *Handler) toDocView(d knowledge.Document, now time.Time) docView {
	v := docView{
		ID: d.ID, Title: d.Title, Chunks: d.Chunks, Stale: d.StaleChunks,
		Updated: h.day(d.UpdatedAt),
		Inbox:   "All inboxes",
		Kind:    "Document",
		Status:  d.Status(now),
		Unused:  d.UseCount == 0,
		Used:    "Not used yet",
	}
	if d.UseCount > 0 {
		times := "times"
		if d.UseCount == 1 {
			times = "time"
		}
		v.Used = fmt.Sprintf("%d %s, last %s", d.UseCount, times, h.day(d.LastUsedAt))
	}
	switch {
	case !d.ValidFrom.IsZero() && !d.ValidUntil.IsZero():
		v.Window = h.day(d.ValidFrom) + " – " + h.day(d.ValidUntil.Add(-time.Nanosecond))
	case !d.ValidUntil.IsZero():
		v.Window = "Until " + h.day(d.ValidUntil.Add(-time.Nanosecond))
	case !d.ValidFrom.IsZero():
		v.Window = "From " + h.day(d.ValidFrom)
	}
	if d.InboxID > 0 {
		v.Inbox = "Inbox " + strconv.FormatInt(d.InboxID, 10)
	}
	if d.Kind == knowledge.KindFAQ {
		v.Kind = "FAQ"
	}
	var words []string
	for _, w := range strings.Fields(d.Content) {
		if strings.Trim(w, "#") != "" { // drop Markdown heading markers
			words = append(words, w)
		}
	}
	preview := []rune(strings.Join(words, " "))
	if len(preview) > 140 {
		preview = append(preview[:140], '…')
	}
	v.Preview = string(preview)
	return v
}

// formFromDoc fills the edit form. The stored end is exclusive (midnight
// after the last day), so the form shows the day before.
func (h *Handler) formFromDoc(d knowledge.Document) docForm {
	f := docForm{ID: d.ID, Kind: string(d.Kind), Synced: knowledge.SyncedKey(d.SourceKey)}
	if d.InboxID > 0 {
		f.InboxID = strconv.FormatInt(d.InboxID, 10)
	}
	if d.Kind == knowledge.KindFAQ {
		f.Question, f.Answer = d.Title, d.Content
	} else {
		f.DocTitle, f.DocContent = d.Title, d.Content
	}
	if !d.ValidFrom.IsZero() {
		f.From = d.ValidFrom.In(h.loc()).Format(time.DateOnly)
	}
	if !d.ValidUntil.IsZero() {
		f.Until = d.ValidUntil.Add(-time.Nanosecond).In(h.loc()).Format(time.DateOnly)
	}
	return f
}

// window turns the form's dates into the stored window: From is the start of
// that day and Until the start of the day after the last day, in the
// business time zone.
func (h *Handler) window(from, until string) (time.Time, time.Time, error) {
	parse := func(v, label string) (time.Time, error) {
		v = strings.TrimSpace(v)
		if v == "" {
			return time.Time{}, nil
		}
		t, err := time.ParseInLocation(time.DateOnly, v, h.loc())
		if err != nil {
			return time.Time{}, fmt.Errorf("%s must be a date like 2026-12-31", label)
		}
		return t, nil
	}
	f, err := parse(from, "Start date")
	if err != nil {
		return f, f, err
	}
	u, err := parse(until, "Last day")
	if err != nil {
		return f, u, err
	}
	if !u.IsZero() {
		u = u.AddDate(0, 0, 1)
	}
	return f, u, nil
}

// num returns a query value only if it is a plain number, so a crafted link
// cannot put its own words into a notice.
func num(q url.Values, key string) string {
	n, err := strconv.Atoi(q.Get(key))
	if err != nil || n < 0 {
		return "?"
	}
	return strconv.Itoa(n)
}

func noticeFor(q url.Values) string {
	switch q.Get("done") {
	case "added":
		if q.Get("pdf") != "" {
			cut := ""
			if q.Get("cut") == "1" {
				cut = fmt.Sprintf(" The PDF was cut off at %d pages or %d characters; split it to add the rest.", pdftext.MaxPages, pdftext.MaxRunes)
			}
			return fmt.Sprintf("Read %s pages from the PDF and indexed them (%s chunks). Open the document and check the text: "+
				"tables lose their layout, and some PDF makers drop Thai tone marks (ไม้เอก, ไม้โท).%s", num(q, "pdf"), num(q, "chunks"), cut)
		}
		return fmt.Sprintf("Added and indexed (%s chunks). The bot can use it right away.", num(q, "chunks"))
	case "page":
		switch q.Get("outcome") {
		case "added":
			return "Page added and indexed. It is checked again every day."
		case "updated":
			return "The page had changed; the bot now uses the new version."
		case "unchanged":
			return "Checked: the page has not changed."
		case "failed":
			return "The page could not be read. See the reason in the list; the last good version stays."
		case "hidden", "deleted":
			return "The page no longer exists, so the bot stopped using it."
		}
	case "page_removed":
		return "Removed. The bot no longer uses it."
	case "feed_started":
		return "Reading the file in the background. Refresh in a minute to see how many rows were added."
	case "page_interval":
		return "Schedule saved."
	case "sync_all":
		return fmt.Sprintf("Checking %s pages now in the background. Refresh in a minute to see the results.", num(q, "count"))
	case "updated":
		return fmt.Sprintf("Saved and re-indexed (%s chunks). The bot uses the new version right away.", num(q, "chunks"))
	case "deleted":
		return "Deleted. The bot no longer uses it."
	case "reindexed":
		return fmt.Sprintf("Re-indexed %s documents with the current embeddings model.", num(q, "count"))
	}
	return ""
}

func accountParam(raw string) int64 {
	n, err := strconv.ParseInt(strings.TrimSpace(raw), 10, 64)
	if err != nil || n < 1 {
		return 1
	}
	return n
}

func (h *Handler) submitKnowledge(w http.ResponseWriter, r *http.Request) {
	if h.Knowledge == nil {
		http.Error(w, "knowledge base disabled: set DATABASE_URL", http.StatusServiceUnavailable)
		return
	}
	var err error
	if strings.HasPrefix(r.Header.Get("Content-Type"), "multipart/form-data") {
		// Only the add-document form uploads files. The file goes to a
		// temporary file (removed after the request), not to memory.
		r.Body = http.MaxBytesReader(w, r.Body, maxUpload)
		err = r.ParseMultipartForm(1 << 20)
	} else {
		r.Body = http.MaxBytesReader(w, r.Body, maxTextUpload)
		err = r.ParseForm()
	}
	if err != nil {
		http.Error(w, "form too large or invalid (max 10 MB for a PDF, 2 MB for text)", http.StatusBadRequest)
		return
	}
	pf := r.PostForm
	acct := accountParam(pf.Get("account"))
	data := knowledgeData{AccountID: acct, docForm: docForm{
		InboxID:  pf.Get("inbox"),
		Question: pf.Get("question"), Answer: pf.Get("answer"),
		DocTitle: pf.Get("title"), DocContent: pf.Get("content"),
		From: pf.Get("valid_from"), Until: pf.Get("valid_until"),
	}}
	fail := func(form string, err error) {
		data.Error, data.ErrorForm = err.Error(), form
		h.renderKnowledge(w, r, http.StatusUnprocessableEntity, data)
	}
	back := "/admin/knowledge?account=" + strconv.FormatInt(acct, 10)

	switch action := pf.Get("action"); action {
	case "add_faq", "add_doc":
		form := "faq"
		doc := knowledge.Document{AccountID: acct, Kind: knowledge.KindFAQ, Title: data.Question, Content: data.Answer}
		if action == "add_doc" {
			form = "doc"
			doc = knowledge.Document{AccountID: acct, Kind: knowledge.KindText, Title: data.DocTitle, Content: data.DocContent}
			pdfPages, err := readUpload(r, &doc)
			if err != nil {
				fail(form, err)
				return
			}
			if pdfPages > 0 {
				back += "&pdf=" + strconv.Itoa(pdfPages)
			} else if pdfPages < 0 {
				back += "&pdf=" + strconv.Itoa(-pdfPages) + "&cut=1"
			}
			data.DocTitle, data.DocContent = doc.Title, doc.Content // keep an uploaded file for "add anyway"
		}
		if err := h.fillScope(&doc, data.docForm); err != nil {
			fail(form, err)
			return
		}
		if pf.Get("confirm_duplicate") != "1" {
			dupes, err := h.Knowledge.Similar(r.Context(), doc)
			if err != nil {
				h.Logger.Warn("duplicate check failed", "account_id", acct, "error", err)
				fail(form, err)
				return
			}
			if len(dupes) > 0 {
				for _, d := range dupes {
					data.Dupes = append(data.Dupes, dupView{DocumentID: d.DocumentID, Title: d.Title,
						Score: strconv.Itoa(int(d.Score*100+0.5)) + "%"})
				}
				data.DupeForm = form
				h.renderKnowledge(w, r, http.StatusOK, data)
				return
			}
		}
		id, chunks, err := h.Knowledge.Add(r.Context(), doc)
		if err != nil {
			h.Logger.Warn("add knowledge failed", "account_id", acct, "error", err)
			fail(form, err)
			return
		}
		h.record(r, acct, "knowledge added", doc.Title, nil)
		h.Logger.Info("knowledge added", "account_id", acct, "document_id", id, "kind", doc.Kind,
			"inbox_id", doc.InboxID, "chunks", chunks, "dated", !doc.ValidFrom.IsZero() || !doc.ValidUntil.IsZero(),
			"remote_addr", r.RemoteAddr)
		http.Redirect(w, r, back+"&done=added&chunks="+strconv.Itoa(chunks), http.StatusSeeOther)
	case "update":
		id, _ := strconv.ParseInt(pf.Get("id"), 10, 64)
		cur, err := h.Knowledge.Get(r.Context(), acct, id)
		if err != nil {
			fail("list", errors.New("that document no longer exists"))
			return
		}
		doc := knowledge.Document{ID: id, AccountID: acct, Kind: cur.Kind, Title: data.DocTitle, Content: data.DocContent}
		if cur.Kind == knowledge.KindFAQ {
			doc.Title, doc.Content = data.Question, data.Answer
		}
		edit := data.docForm
		edit.ID, edit.Kind = id, string(cur.Kind)
		data.Edit = &edit
		if err := h.fillScope(&doc, data.docForm); err != nil {
			fail("edit", err)
			return
		}
		chunks, err := h.Knowledge.Update(r.Context(), doc)
		if err != nil {
			h.Logger.Warn("update knowledge failed", "account_id", acct, "document_id", id, "error", err)
			fail("edit", err)
			return
		}
		h.record(r, acct, "knowledge edited", doc.Title, docCopy(cur))
		h.Logger.Info("knowledge updated", "account_id", acct, "document_id", id, "chunks", chunks, "remote_addr", r.RemoteAddr)
		http.Redirect(w, r, back+"&done=updated&chunks="+strconv.Itoa(chunks), http.StatusSeeOther)
	case "add_page", "sync_page", "remove_page", "page_interval", "sync_all":
		h.webAction(w, r, acct, pf.Get("action"), data)
	case "delete":
		id, _ := strconv.ParseInt(pf.Get("id"), 10, 64)
		before, getErr := h.Knowledge.Get(r.Context(), acct, id)
		if err := h.Knowledge.Delete(r.Context(), acct, id); err != nil {
			fail("list", err)
			return
		}
		if getErr == nil {
			h.record(r, acct, "knowledge deleted", before.Title, docCopy(before))
		}
		h.Logger.Info("knowledge deleted", "account_id", acct, "document_id", id, "remote_addr", r.RemoteAddr)
		http.Redirect(w, r, back+"&done=deleted", http.StatusSeeOther)
	case "reindex":
		n, err := h.Knowledge.Reindex(r.Context(), acct, false)
		if err != nil {
			h.Logger.Warn("reindex failed", "account_id", acct, "reindexed", n, "error", err)
			fail("list", err)
			return
		}
		h.record(r, acct, "knowledge re-indexed", strconv.Itoa(n)+" documents", nil)
		h.Logger.Info("knowledge reindexed", "account_id", acct, "documents", n, "remote_addr", r.RemoteAddr)
		http.Redirect(w, r, back+"&done=reindexed&count="+strconv.Itoa(n), http.StatusSeeOther)
	default:
		http.Error(w, "unknown action", http.StatusBadRequest)
	}
}

// fillScope sets the inbox and validity window from the form.
func (h *Handler) fillScope(doc *knowledge.Document, f docForm) error {
	inbox, err := inboxParam(f.InboxID)
	if err != nil {
		return err
	}
	from, until, err := h.window(f.From, f.Until)
	if err != nil {
		return err
	}
	doc.InboxID, doc.ValidFrom, doc.ValidUntil = inbox, from, until
	return nil
}

func inboxParam(raw string) (int64, error) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return 0, nil
	}
	n, err := strconv.ParseInt(raw, 10, 64)
	if err != nil || n < 1 {
		return 0, errors.New("inbox ID must be blank (all inboxes) or a positive number")
	}
	return n, nil
}

// readUpload replaces the pasted content with an uploaded .txt/.md/.pdf
// file, if any, and returns the pages read from a PDF (0 otherwise). A blank
// title takes the first Markdown heading, else the file name.
func readUpload(r *http.Request, doc *knowledge.Document) (pdfPages int, err error) {
	if r.MultipartForm == nil || len(r.MultipartForm.File["file"]) == 0 {
		return 0, nil
	}
	fh := r.MultipartForm.File["file"][0]
	if fh.Filename == "" || fh.Size == 0 {
		return 0, nil
	}
	ext := strings.ToLower(filepath.Ext(fh.Filename))
	if ext != ".pdf" && !allowedUploads[ext] {
		return 0, fmt.Errorf("file type %q is not supported; upload .txt, .md or .pdf (Word: save as PDF first)", ext)
	}
	f, err := fh.Open()
	if err != nil {
		return 0, err
	}
	defer f.Close()
	if ext == ".pdf" {
		if fh.Size > pdftext.MaxBytes {
			return 0, pdftext.ErrTooLarge
		}
		raw, err := io.ReadAll(io.LimitReader(f, pdftext.MaxBytes+1))
		if err != nil {
			return 0, err
		}
		res, err := pdftext.Extract(r.Context(), raw)
		if err != nil {
			return 0, err
		}
		doc.Content = res.Text
		if strings.TrimSpace(doc.Title) == "" {
			doc.Title = strings.TrimSuffix(filepath.Base(fh.Filename), filepath.Ext(fh.Filename))
		}
		if res.Truncated {
			return -res.Pages, nil // negative: the PDF was cut off at the limits
		}
		return res.Pages, nil
	}
	raw, err := io.ReadAll(io.LimitReader(f, maxTextUpload+1))
	if err != nil {
		return 0, err
	}
	if len(raw) > maxTextUpload {
		return 0, errors.New("the text file is larger than 2 MB; split it into several documents")
	}
	raw = bytes.TrimPrefix(raw, []byte("\xef\xbb\xbf")) // UTF-8 BOM
	if !utf8.Valid(raw) {
		return 0, errors.New("the file is not UTF-8 text; save it as UTF-8 and try again")
	}
	doc.Content = string(raw)
	if strings.TrimSpace(doc.Title) == "" {
		doc.Title = knowledge.FirstHeading(doc.Content)
	}
	if strings.TrimSpace(doc.Title) == "" {
		doc.Title = strings.TrimSuffix(filepath.Base(fh.Filename), filepath.Ext(fh.Filename))
	}
	return 0, nil
}

// docCopy is what the audit trail keeps of a document before a change.
func docCopy(d knowledge.Document) map[string]any {
	m := map[string]any{"id": d.ID, "key": d.SourceKey, "kind": d.Kind, "title": d.Title, "content": d.Content, "inbox_id": d.InboxID}
	if !d.ValidFrom.IsZero() {
		m["valid_from"] = d.ValidFrom
	}
	if !d.ValidUntil.IsZero() {
		m["valid_until"] = d.ValidUntil
	}
	return m
}

// webAction adds, syncs or removes a website page.
// startFeedCheck claims a new feed and reads it in the background.
func (h *Handler) startFeedCheck(w http.ResponseWriter, r *http.Request, back string, src websync.Source) {
	if claimed, err := h.Web.ClaimOne(r.Context(), src.AccountID, src.ID); err == nil {
		h.WebSync.CheckLater(r.Context(), claimed)
	} else {
		h.WebSync.Kick() // the scheduler picks it up
	}
	http.Redirect(w, r, back+"&done=feed_started", http.StatusSeeOther)
}

func (h *Handler) webAction(w http.ResponseWriter, r *http.Request, acct int64, action string, data knowledgeData) {
	if h.Web == nil || h.WebSync == nil {
		http.Error(w, "website pages need DATABASE_URL", http.StatusServiceUnavailable)
		return
	}
	back := "/admin/knowledge?account=" + strconv.FormatInt(acct, 10)
	fail := func(msg string) {
		data.Error, data.ErrorForm = msg, "page"
		h.renderKnowledge(w, r, http.StatusUnprocessableEntity, data)
	}
	var src websync.Source
	switch action {
	case "add_page":
		data.PageURL = r.PostForm.Get("url")
		u, err := webfetch.CheckURL(data.PageURL)
		if err != nil {
			fail(err.Error())
			return
		}
		if h.Knowledge == nil || h.Knowledge.Embedder.Model() == "" {
			fail("Set an embeddings provider on the AI providers page first.")
			return
		}
		kind := websync.KindPage
		if r.PostForm.Get("kind") == websync.KindFeed {
			kind = websync.KindFeed
		}
		data.PageKind = kind
		if src, err = h.Web.Add(r.Context(), acct, u.String(), kind); err != nil {
			if errors.Is(err, websync.ErrDuplicate) || errors.Is(err, websync.ErrTooMany) {
				fail(err.Error())
				return
			}
			h.Logger.Error("add web page", "account_id", acct, "error", err)
			fail("Could not add the page. Try again.")
			return
		}
		if kind == websync.KindFeed {
			h.record(r, acct, "data feed added", u.Host+u.Path, nil)
			h.startFeedCheck(w, r, back, src)
			return
		}
		h.record(r, acct, "web page added", u.Host+u.Path, nil)
	case "page_interval":
		id, _ := strconv.ParseInt(r.PostForm.Get("id"), 10, 64)
		hours, _ := strconv.Atoi(r.PostForm.Get("interval"))
		if !slices.Contains(websync.Intervals, hours) {
			fail("Choose one of the listed schedules.")
			return
		}
		if err := h.Web.SetInterval(r.Context(), acct, id, hours); err != nil {
			fail("That page is no longer in the list.")
			return
		}
		h.record(r, acct, "web page schedule changed", strconv.Itoa(hours)+" h", nil)
		http.Redirect(w, r, back+"&done=page_interval", http.StatusSeeOther)
		return
	case "sync_all":
		n, err := h.Web.MarkAllDue(r.Context(), acct)
		if err != nil {
			fail("Could not start the sync. Try again.")
			return
		}
		h.WebSync.Kick()
		h.record(r, acct, "sync all started", strconv.Itoa(n)+" pages", nil)
		http.Redirect(w, r, back+"&done=sync_all&count="+strconv.Itoa(n), http.StatusSeeOther)
		return
	case "remove_page":
		id, _ := strconv.ParseInt(r.PostForm.Get("id"), 10, 64)
		src, err := h.Web.Get(r.Context(), acct, id)
		if err != nil {
			fail("That page is no longer in the list.")
			return
		}
		// The documents go first: if that fails the source stays listed, never orphaned.
		doc, _ := h.Knowledge.GetByKey(r.Context(), acct, websync.Key(src.URL)) // the page's copy for the history
		removed, err := h.WebSync.RemoveDocuments(r.Context(), src)
		if err != nil {
			h.Logger.Error("remove source documents", "account_id", acct, "source_id", id, "removed", removed, "error", err)
			fail("Could not remove it. Try again.")
			return
		}
		if err := h.Web.Remove(r.Context(), acct, id); err != nil && !errors.Is(err, websync.ErrNotFound) {
			h.Logger.Error("remove web page", "account_id", acct, "source_id", id, "error", err)
			fail("Could not remove the page. Try again.")
			return
		}
		if src.IsFeed() {
			h.record(r, acct, "data feed removed", src.Title+" ("+strconv.Itoa(removed)+" documents)", nil)
		} else {
			h.record(r, acct, "web page removed", src.Title, docCopy(doc))
		}
		http.Redirect(w, r, back+"&done=page_removed", http.StatusSeeOther)
		return
	case "sync_page":
		id, _ := strconv.ParseInt(r.PostForm.Get("id"), 10, 64)
		var err error
		if src, err = h.Web.ClaimOne(r.Context(), acct, id); err != nil {
			if errors.Is(err, websync.ErrBusy) {
				fail(err.Error())
				return
			}
			fail("That page is no longer in the list.")
			return
		}
		if src.IsFeed() {
			h.WebSync.CheckLater(r.Context(), src)
			http.Redirect(w, r, back+"&done=feed_started", http.StatusSeeOther)
			return
		}
	}
	outcome, _ := h.WebSync.Check(r.Context(), src)
	http.Redirect(w, r, back+"&done=page&outcome="+string(outcome), http.StatusSeeOther)
}
