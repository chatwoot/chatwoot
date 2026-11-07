package admin

import (
	"context"
	"errors"
	"fmt"
	"io"
	"math"
	"mime/multipart"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/bot"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/memory"
)

// Tester runs the bot's reply pipeline without Chatwoot (bot.Bot.PreviewMedia).
// With no uploads it is the plain text preview.
type Tester interface {
	PreviewMedia(ctx context.Context, acct, inbox int64, history []memory.Turn, uploads []bot.Upload) bot.Preview
}

const (
	maxTestTurns = 12   // earlier turns are dropped, like a short chat
	maxTestRunes = 2000 // per message

	// Uploads: the bot reads at most 3 images and one voice note per message,
	// so 4 files; the largest it accepts is a 10 MB voice note.
	maxTestFiles     = 4
	maxTestFileBytes = 10 << 20
	maxTestFormBytes = 256 << 10
	maxTestBodyBytes = 3*maxTestFileBytes + maxTestFormBytes
)

var errTestTooLarge = errors.New("too large")

// formError is a message for the owner, shown on the page as written.
type formError string

func (e formError) Error() string { return string(e) }

type testSource struct {
	Title string
	Score string
}

type testData struct {
	AccountID  int64
	Inbox      string
	Enabled    bool
	Turns      []memory.Turn
	Asked      string // the latest test question, for "add this answer"
	Sent       bool   // a message was answered; shows the side panel
	Handoff    bool
	Reason     string
	Sources    []testSource
	Model      string
	LatencyMS  int64
	Error      string
	Knowledge  bool
	Files      []testUpload
	Media      []string // what the bot read: "Voice note", "Photo", "Sticker"
	Transcript string
}

type testUpload struct {
	Name string
	Size string
}

var mediaLabel = map[string]string{"voice": "Voice note", "image": "Photo", "sticker": "Sticker"}

var reasonText = map[string]string{
	bot.ReasonCustomerAsked: "The message asks for a person, so the bot passes the chat to staff without answering.",
	bot.ReasonAIRequest:     "The AI decided staff should answer this one, and passes the chat to staff.",
	bot.ReasonLLMError:      "The AI model failed. Check the AI providers page. Customers would get the failure message and staff would take over.",
	bot.ReasonAttachment: "The bot could not read the file, so it thanks the customer and passes the chat to staff. " +
		"Voice notes, images and stickers must be switched on in the Business profile; other file types (PDF, video) always go to staff.",
}

func (h *Handler) showTest(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	h.renderPage(w, r, http.StatusOK, "test.html", testData{
		AccountID: accountParam(q.Get("account")), Inbox: q.Get("inbox"),
		Enabled: h.Tester != nil, Knowledge: h.Knowledge != nil,
	})
}

// submitTest answers one test message. The conversation so far travels in
// hidden form fields, so nothing is stored on the server, and nothing is
// sent to Chatwoot, kept in chat memory or traced.
func (h *Handler) submitTest(w http.ResponseWriter, r *http.Request) {
	uploads, err := parseTestForm(w, r)
	if err != nil && !errors.Is(err, errTestTooLarge) && r.PostForm == nil {
		http.Error(w, "form too large or invalid", http.StatusBadRequest)
		return
	}
	acct := accountParam(r.PostForm.Get("account"))
	d := testData{AccountID: acct, Inbox: r.PostForm.Get("inbox"), Enabled: h.Tester != nil, Knowledge: h.Knowledge != nil}
	d.Turns = historyFromForm(r.PostForm["role"], r.PostForm["text"])
	if errors.Is(err, errTestTooLarge) {
		d.Error = fmt.Sprintf("The files are too large. Attach up to %d files, %d MB in total.", maxTestFiles, maxTestBodyBytes>>20)
		h.renderPage(w, r, http.StatusRequestEntityTooLarge, "test.html", d)
		return
	}
	if !d.Enabled {
		h.renderPage(w, r, http.StatusServiceUnavailable, "test.html", d)
		return
	}
	inbox, inboxErr := inboxParam(d.Inbox)
	msg := clip(strings.TrimSpace(r.PostForm.Get("message")))
	switch {
	case err != nil:
		d.Error = err.Error()
	case inboxErr != nil:
		d.Error = inboxErr.Error()
	case msg == "" && len(uploads) == 0:
		d.Error = "Type a message or attach a file."
	}
	if d.Error != "" {
		h.renderPage(w, r, http.StatusUnprocessableEntity, "test.html", d)
		return
	}

	d.Turns = trimTurns(append(d.Turns, memory.Turn{Role: "user", Content: msg}))
	started := time.Now()
	p := h.Tester.PreviewMedia(r.Context(), acct, inbox, d.Turns, uploads)
	d.LatencyMS = time.Since(started).Milliseconds()
	if p.Input != "" { // what the bot read: typed text plus transcript and file notes
		d.Turns[len(d.Turns)-1].Content = clip(p.Input)
	}
	d.Turns = append(d.Turns, memory.Turn{Role: "assistant", Content: p.Reply})
	d.Sent, d.Asked, d.Handoff, d.Reason, d.Model = true, msg, p.Handoff, reasonText[p.Reason], p.Model
	if d.Asked == "" {
		d.Asked = p.Transcript
	}
	for _, u := range uploads {
		d.Files = append(d.Files, testUpload{Name: u.Name, Size: sizeLabel(len(u.Data))})
	}
	for _, kind := range strings.Split(p.Media, ",") {
		if l := mediaLabel[kind]; l != "" {
			d.Media = append(d.Media, l)
		}
	}
	d.Transcript = p.Transcript
	for _, hit := range p.Sources {
		d.Sources = append(d.Sources, testSource{Title: hit.Title, Score: strconv.Itoa(int(math.Round(hit.Score*100))) + "%"})
	}
	// Metadata only: test messages are business content but may be pasted
	// from real customers, so their text, transcripts and file names are never logged.
	h.Logger.Info("admin test reply", "account_id", acct, "inbox_id", inbox, "handoff", p.Handoff,
		"reason", p.Reason, "sources", len(p.Sources), "model", p.Model, "latency_ms", d.LatencyMS,
		"turns", len(d.Turns), "files", len(uploads), "media", p.Media, "failed", p.Err != nil)
	if p.Err != nil {
		h.Logger.Warn("admin test reply failed", "account_id", acct, "error", p.Err)
	}
	h.renderPage(w, r, http.StatusOK, "test.html", d)
}

// parseTestForm reads the test form, urlencoded or multipart. Uploads are
// capped by count and size before anything reaches the bot. A non-nil error
// with PostForm set is a user error to show on the page.
func parseTestForm(w http.ResponseWriter, r *http.Request) ([]bot.Upload, error) {
	multipartForm := strings.HasPrefix(r.Header.Get("Content-Type"), "multipart/form-data")
	if !multipartForm {
		r.Body = http.MaxBytesReader(w, r.Body, maxTestFormBytes)
		return nil, r.ParseForm()
	}
	r.Body = http.MaxBytesReader(w, r.Body, maxTestBodyBytes)
	if err := r.ParseMultipartForm(maxTestFormBytes); err != nil {
		var tooBig *http.MaxBytesError
		if errors.As(err, &tooBig) {
			r.PostForm = map[string][]string{}
			return nil, errTestTooLarge
		}
		return nil, err
	}
	defer func() { _ = r.MultipartForm.RemoveAll() }()
	var uploads []bot.Upload
	for _, fh := range r.MultipartForm.File["files"] {
		if fh.Filename == "" && fh.Size == 0 {
			continue // no file chosen
		}
		if len(uploads) == maxTestFiles {
			return nil, formError(fmt.Sprintf("Attach up to %d files per message.", maxTestFiles))
		}
		if fh.Size > maxTestFileBytes {
			return nil, formError(fmt.Sprintf("%s is over %d MB.", clip(fh.Filename), maxTestFileBytes>>20))
		}
		data, err := readTestFile(fh)
		if err != nil {
			return nil, formError("Could not read " + clip(fh.Filename) + ".")
		}
		uploads = append(uploads, bot.Upload{Name: fh.Filename, Data: data})
	}
	return uploads, nil
}

func readTestFile(fh *multipart.FileHeader) ([]byte, error) {
	f, err := fh.Open()
	if err != nil {
		return nil, err
	}
	defer func() { _ = f.Close() }()
	return io.ReadAll(io.LimitReader(f, maxTestFileBytes))
}

func sizeLabel(n int) string {
	if n < 1<<20 {
		return fmt.Sprintf("%d KB", (n+1023)>>10)
	}
	return fmt.Sprintf("%.1f MB", float64(n)/(1<<20))
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
