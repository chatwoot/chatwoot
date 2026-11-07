package admin

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"path/filepath"
	"strconv"
	"strings"
	"unicode/utf8"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
)

// maxUpload bounds a knowledge form post (file upload included).
const maxUpload = 2 << 20

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
	Disabled bool
}

type knowledgeData struct {
	Enabled   bool // a database is configured
	Embedding string
	AccountID int64
	Docs      []docView
	Stale     int
	Notice    string
	Error     string
	ErrorForm string // which form the error belongs to: faq, doc, list
	// Values re-filled after a failed add.
	InboxID              string
	Question, Answer     string
	DocTitle, DocContent string
}

func (h *Handler) showKnowledge(w http.ResponseWriter, r *http.Request) {
	data := knowledgeData{AccountID: accountParam(r.URL.Query().Get("account"))}
	data.Notice = noticeFor(r.URL.Query())
	h.renderKnowledge(w, r, http.StatusOK, data)
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
		for _, d := range docs {
			data.Docs = append(data.Docs, toDocView(d))
			data.Stale += d.StaleChunks
		}
	}
	h.renderPage(w, r, status, "knowledge.html", data)
}

func toDocView(d knowledge.Document) docView {
	v := docView{
		ID: d.ID, Title: d.Title, Chunks: d.Chunks, Stale: d.StaleChunks,
		Updated: d.UpdatedAt.UTC().Format("2006-01-02 15:04 UTC"),
		Inbox:   "All inboxes",
		Kind:    "Document",
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

func noticeFor(q url.Values) string {
	switch q.Get("done") {
	case "added":
		return fmt.Sprintf("Added and indexed (%s chunks). The bot can use it right away.", q.Get("chunks"))
	case "deleted":
		return "Deleted. The bot no longer uses it."
	case "reindexed":
		return fmt.Sprintf("Re-indexed %s documents with the current embeddings model.", q.Get("count"))
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
	r.Body = http.MaxBytesReader(w, r.Body, maxUpload)
	var err error
	if strings.HasPrefix(r.Header.Get("Content-Type"), "multipart/form-data") {
		err = r.ParseMultipartForm(maxUpload)
	} else {
		err = r.ParseForm()
	}
	if err != nil {
		http.Error(w, "form too large or invalid (max 2 MB)", http.StatusBadRequest)
		return
	}
	acct := accountParam(r.PostForm.Get("account"))
	data := knowledgeData{
		AccountID: acct,
		InboxID:   r.PostForm.Get("inbox"),
		Question:  r.PostForm.Get("question"), Answer: r.PostForm.Get("answer"),
		DocTitle: r.PostForm.Get("title"), DocContent: r.PostForm.Get("content"),
	}
	fail := func(form string, err error) {
		data.Error, data.ErrorForm = err.Error(), form
		h.renderKnowledge(w, r, http.StatusUnprocessableEntity, data)
	}
	back := "/admin/knowledge?account=" + strconv.FormatInt(acct, 10)

	switch action := r.PostForm.Get("action"); action {
	case "add_faq", "add_doc":
		form := "faq"
		doc := knowledge.Document{AccountID: acct, Kind: knowledge.KindFAQ, Title: data.Question, Content: data.Answer}
		if action == "add_doc" {
			form = "doc"
			doc = knowledge.Document{AccountID: acct, Kind: knowledge.KindText, Title: data.DocTitle, Content: data.DocContent}
			if err := readUpload(r, &doc); err != nil {
				fail(form, err)
				return
			}
		}
		inbox, err := inboxParam(data.InboxID)
		if err != nil {
			fail(form, err)
			return
		}
		doc.InboxID = inbox
		id, chunks, err := h.Knowledge.Add(r.Context(), doc)
		if err != nil {
			h.Logger.Warn("add knowledge failed", "account_id", acct, "error", err)
			fail(form, err)
			return
		}
		h.Logger.Info("knowledge added", "account_id", acct, "document_id", id, "kind", doc.Kind,
			"inbox_id", doc.InboxID, "chunks", chunks, "remote_addr", r.RemoteAddr)
		http.Redirect(w, r, back+"&done=added&chunks="+strconv.Itoa(chunks), http.StatusSeeOther)
	case "delete":
		id, _ := strconv.ParseInt(r.PostForm.Get("id"), 10, 64)
		if err := h.Knowledge.Delete(r.Context(), acct, id); err != nil {
			fail("list", err)
			return
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
		h.Logger.Info("knowledge reindexed", "account_id", acct, "documents", n, "remote_addr", r.RemoteAddr)
		http.Redirect(w, r, back+"&done=reindexed&count="+strconv.Itoa(n), http.StatusSeeOther)
	default:
		http.Error(w, "unknown action", http.StatusBadRequest)
	}
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

// readUpload replaces the pasted content with an uploaded .txt/.md file, if any.
// A blank title takes the first Markdown heading, else the file name.
func readUpload(r *http.Request, doc *knowledge.Document) error {
	if r.MultipartForm == nil || len(r.MultipartForm.File["file"]) == 0 {
		return nil
	}
	fh := r.MultipartForm.File["file"][0]
	if fh.Filename == "" || fh.Size == 0 {
		return nil
	}
	ext := strings.ToLower(filepath.Ext(fh.Filename))
	if !allowedUploads[ext] {
		return fmt.Errorf("file type %q is not supported yet; upload .txt or .md (PDF and DOCX come later)", ext)
	}
	f, err := fh.Open()
	if err != nil {
		return err
	}
	defer f.Close()
	raw, err := io.ReadAll(io.LimitReader(f, maxUpload))
	if err != nil {
		return err
	}
	raw = bytes.TrimPrefix(raw, []byte("\xef\xbb\xbf")) // UTF-8 BOM
	if !utf8.Valid(raw) {
		return errors.New("the file is not UTF-8 text; save it as UTF-8 and try again")
	}
	doc.Content = string(raw)
	if strings.TrimSpace(doc.Title) == "" {
		doc.Title = knowledge.FirstHeading(doc.Content)
	}
	if strings.TrimSpace(doc.Title) == "" {
		doc.Title = strings.TrimSuffix(filepath.Base(fh.Filename), filepath.Ext(fh.Filename))
	}
	return nil
}
