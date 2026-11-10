package admin

import (
	"context"
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/comments"
)

// CommentQueue lists Facebook Page comments that may be leads and sends or
// dismisses them (comments.Queue).
type CommentQueue interface {
	Waiting(ctx context.Context, accountID int64) ([]comments.Comment, error)
	Recent(ctx context.Context, accountID int64, limit int) ([]comments.Comment, error)
	Send(ctx context.Context, accountID, id int64, version int, text, by string) error
	Dismiss(ctx context.Context, accountID, id int64, version int, by string) error
	ReviewStats(ctx context.Context, accountID int64) (comments.ReviewStats, error)
	CanSend() bool
}

type commentsData struct {
	Enabled bool
	CanSend bool
	Account int64
	Items   []commentItem
	Recent  []commentRow
	Stats   comments.ReviewStats
	Done    string // "sent" or "dismissed" after a decision
	Error   string
}

type commentItem struct {
	ID       int64
	Version  int
	From     string
	When     string
	Left     string // time left to reply, or "" when expired
	Expired  bool
	Intent   string
	Reason   string
	Message  string
	Draft    string
	PostURL  string
	LastFail string
	Shadow   string // the shadow reviewer's call, or ""
	Hold     bool   // the shadow reviewer would hold it
}

type commentRow struct {
	When, From, Status, Message, Reply string
	Shadow                             string // "Agreed", "Would have sent", "Would have held", or ""
}

var agreementLabels = map[string]string{"agreed": "Agreed", "too_loose": "Would have sent", "too_strict": "Would have held"}

var intentLabels = map[comments.Intent]string{
	comments.IntentLead: "Likely buyer", comments.IntentQuestion: "Question",
	comments.IntentComplaint: "Complaint", comments.IntentOther: "Not a lead",
	"": "Not sorted",
}

var statusLabels = map[comments.Status]string{
	comments.StatusIgnored: "Not a lead", comments.StatusSending: "Sending",
	comments.StatusSent: "Replied", comments.StatusDismissed: "Dismissed", comments.StatusFailed: "Meta refused",
}

func (h *Handler) showComments(w http.ResponseWriter, r *http.Request) {
	data := commentsData{Account: accountParam(r.URL.Query().Get("account"))}
	if d := r.URL.Query().Get("done"); d == "sent" || d == "dismissed" {
		data.Done = d
	}
	h.renderComments(w, r, http.StatusOK, data)
}

func (h *Handler) submitComments(w http.ResponseWriter, r *http.Request) {
	if h.Comments == nil {
		http.Error(w, "page comments are off: set META_APP_SECRET, META_VERIFY_TOKEN, META_PAGE_ID and DATABASE_URL", http.StatusServiceUnavailable)
		return
	}
	// A 2,000-character Thai reply is about 6 KB; nothing legitimate is bigger.
	r.Body = http.MaxBytesReader(w, r.Body, 16<<10)
	if err := r.ParseForm(); err != nil {
		http.Error(w, "invalid form", http.StatusBadRequest)
		return
	}
	f := r.PostForm
	acct, err1 := strconv.ParseInt(strings.TrimSpace(f.Get("account")), 10, 64)
	id, err2 := strconv.ParseInt(f.Get("id"), 10, 64)
	version, err3 := strconv.Atoi(f.Get("version"))
	decision := f.Get("decision")
	if err1 != nil || err2 != nil || err3 != nil || acct < 1 || id < 1 || version < 1 || (decision != "send" && decision != "dismiss") {
		http.Error(w, "account, id, version and decision (send or dismiss) are required", http.StatusBadRequest)
		return
	}
	ctx := context.WithoutCancel(r.Context())
	var err error
	done := "dismissed"
	if decision == "send" {
		done = "sent"
		err = h.Comments.Send(ctx, acct, id, version, f.Get("reply"), actor(r))
	} else {
		err = h.Comments.Dismiss(ctx, acct, id, version, actor(r))
	}
	if err == nil {
		h.Logger.Info("page comment "+done, "account_id", acct, "comment_row", id)
		http.Redirect(w, r, "/admin/comments?account="+strconv.FormatInt(acct, 10)+"&done="+done, http.StatusSeeOther)
		return
	}
	status, msg := commentError(err)
	if status >= http.StatusInternalServerError {
		h.Logger.Error("page comment "+decision+" failed", "account_id", acct, "comment_row", id, "error", err)
	} else {
		h.Logger.Warn("page comment "+decision+" refused", "account_id", acct, "comment_row", id, "error", err)
	}
	h.renderComments(w, r, status, commentsData{Account: acct, Error: msg})
}

// commentError turns a queue error into a status and a message for the owner.
func commentError(err error) (int, string) {
	var refused *comments.SendError
	switch {
	case errors.Is(err, comments.ErrNotRecorded):
		return http.StatusInternalServerError, "Sent, but saving that failed. Do not send it again; it shows as Sending in the history."
	case errors.Is(err, comments.ErrEmptyReply):
		return http.StatusUnprocessableEntity, "Write a reply before sending."
	case errors.Is(err, comments.ErrLongReply):
		return http.StatusUnprocessableEntity, "The reply is too long. Messenger allows 2,000 characters."
	case errors.Is(err, comments.ErrSendingOff):
		return http.StatusServiceUnavailable, "Sending is off until a Page access token (META_PAGE_TOKEN) is set. Nothing was sent."
	case errors.Is(err, comments.ErrExpired):
		return http.StatusConflict, "Facebook allows a private reply only within 7 days of the comment. Nothing was sent; dismiss it instead."
	case errors.Is(err, comments.ErrChanged):
		return http.StatusConflict, "This comment changed after you opened the page. Nothing was sent; check it again below."
	case errors.Is(err, comments.ErrNotFound):
		return http.StatusNotFound, "That comment is no longer waiting. It may have been answered, dismissed or deleted."
	case errors.Is(err, comments.ErrSendRefused) && errors.As(err, &refused):
		return http.StatusConflict, "Facebook will not accept a private reply to this comment (" + refused.Message + "). It was moved to the history."
	default:
		return http.StatusBadGateway, "Not sent. The comment still waits; try again. If it keeps failing, check the Page access token and the service logs."
	}
}

func (h *Handler) renderComments(w http.ResponseWriter, r *http.Request, status int, data commentsData) {
	data.Enabled = h.Comments != nil
	if data.Enabled {
		data.CanSend = h.Comments.CanSend()
		if err := h.loadComments(r.Context(), &data); err != nil {
			h.Logger.Error("load page comments", "account_id", data.Account, "error", err)
			data.Error = "Could not load the comments. Check the database connection."
		}
	}
	h.renderPage(w, r, status, "comments.html", data)
}

func (h *Handler) loadComments(ctx context.Context, data *commentsData) error {
	waiting, err := h.Comments.Waiting(ctx, data.Account)
	if err != nil {
		return err
	}
	recent, err := h.Comments.Recent(ctx, data.Account, 20)
	if err != nil {
		return err
	}
	if data.Stats, err = h.Comments.ReviewStats(ctx, data.Account); err != nil {
		return err
	}
	now := time.Now()
	for _, c := range waiting {
		it := commentItem{ID: c.ID, Version: c.Version, From: orUnknown(c.FromName), When: h.stamp(c.CreatedAt),
			Expired: c.Expired(now), Intent: intentLabels[c.Intent], Reason: c.Reason, Message: c.Message,
			Draft: c.Draft, PostURL: postURL(c.PostID), LastFail: c.Error}
		if !it.Expired {
			it.Left = timeLeft(c.CreatedAt.Add(comments.ReplyWindow).Sub(now))
		}
		if c.Review != nil {
			it.Hold = !c.Review.Pass
			it.Shadow = "Would send it as drafted"
			if it.Hold {
				it.Shadow = "Would hold it: " + c.Review.Reason
			}
		}
		data.Items = append(data.Items, it)
	}
	for _, c := range recent {
		when := c.DecidedAt
		if when.IsZero() {
			when = c.Received
		}
		row := commentRow{When: h.stamp(when), From: orUnknown(c.FromName),
			Status: statusLabels[c.Status], Message: preview(c.Message), Reply: preview(c.Reply)}
		if c.Review != nil && (c.Status == comments.StatusSent || c.Status == comments.StatusDismissed) {
			row.Shadow = agreementLabels[comments.Agreement(c)]
		}
		data.Recent = append(data.Recent, row)
	}
	return nil
}

func (h *Handler) stamp(t time.Time) string { return t.In(h.loc()).Format("2 Jan 15:04") }

// postURL links to the post on Facebook. Post IDs are "<page>_<post>",
// digits only; anything else gets no link.
func postURL(postID string) string {
	for _, r := range postID {
		if (r < '0' || r > '9') && r != '_' {
			return ""
		}
	}
	if postID == "" {
		return ""
	}
	return "https://www.facebook.com/" + postID
}

func timeLeft(d time.Duration) string {
	if d >= 48*time.Hour {
		return strconv.Itoa(int(d.Hours()/24)) + " days left to reply"
	}
	if d >= 2*time.Hour {
		return strconv.Itoa(int(d.Hours())) + " hours left to reply"
	}
	return "Less than 2 hours left to reply"
}

func orUnknown(name string) string {
	if strings.TrimSpace(name) == "" {
		return "Facebook user"
	}
	return name
}

func preview(s string) string {
	s = strings.Join(strings.Fields(s), " ")
	if r := []rune(s); len(r) > 80 {
		return string(r[:80]) + "…"
	}
	return s
}
