package admin

import (
	"context"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/comments"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/llm"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/settings"
)

type recordingSender struct{ sent []string }

func (s *recordingSender) SendPrivateReply(_ context.Context, commentID, text string) error {
	s.sent = append(s.sent, commentID+"|"+text)
	return nil
}

type commentsEnv struct {
	mux    *http.ServeMux
	store  *comments.Memory
	sender *recordingSender
}

func newCommentsEnv(t *testing.T, enabled, canSend bool) *commentsEnv {
	t.Helper()
	store, err := settings.Open(t.TempDir()+"/s.json", settings.LLM{})
	if err != nil {
		t.Fatal(err)
	}
	e := &commentsEnv{store: &comments.Memory{}, sender: &recordingSender{}}
	h := &Handler{Password: pw, Store: store, Switch: &llm.Switch{}, Timeout: time.Second,
		Logger: slog.New(slog.NewJSONHandler(io.Discard, nil))}
	if enabled {
		q := &comments.Queue{Store: e.store}
		if canSend {
			q.Sender = e.sender
		}
		h.Comments = q
	}
	e.mux = http.NewServeMux()
	h.Routes(e.mux)
	return e
}

// waiting stores a scored comment for acct and returns it.
func (e *commentsEnv) waiting(t *testing.T, acct int64, commentID, message string, created time.Time) comments.Comment {
	t.Helper()
	ctx := context.Background()
	if _, err := e.store.Add(ctx, comments.Comment{AccountID: acct, PageID: "1111", CommentID: commentID, PostID: "1111_2222",
		FromID: "9", FromName: "Somchai", Message: message, CreatedAt: created}); err != nil {
		t.Fatal(err)
	}
	list, _ := e.store.Unscored(ctx, 10)
	for _, c := range list {
		if c.CommentID == commentID {
			_ = e.store.Score(ctx, c.ID, comments.IntentLead, "Asks the price.", "สวัสดีค่ะ ส่งรายละเอียดทางแชทนะคะ")
			got, _ := e.store.Get(ctx, acct, c.ID)
			return got
		}
	}
	t.Fatal("not stored")
	return comments.Comment{}
}

func commentsPost(v url.Values) *http.Request {
	r := httptest.NewRequest(http.MethodPost, "/admin/comments", strings.NewReader(v.Encode()))
	r.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	r.Header.Set("Sec-Fetch-Site", "same-origin")
	r.SetBasicAuth(Username, pw)
	return r
}

func commentsGet(query string) *http.Request {
	r := httptest.NewRequest(http.MethodGet, "/admin/comments?"+query, nil)
	r.SetBasicAuth(Username, pw)
	return r
}

func decide(c comments.Comment, acct int64, decision, reply string) url.Values {
	return url.Values{"account": {strconv.FormatInt(acct, 10)}, "id": {strconv.FormatInt(c.ID, 10)},
		"version": {strconv.Itoa(c.Version)}, "decision": {decision}, "reply": {reply}}
}

func TestComments_ListsWaitingCommentsOfTheAccountOnly(t *testing.T) {
	// Arrange
	e := newCommentsEnv(t, true, true)
	e.waiting(t, 2, "c1", "สนใจค่ะ <b>ราคา</b>?", time.Now().Add(-time.Hour))
	e.waiting(t, 3, "c2", "Other account secret", time.Now())

	// Act
	res := serve(e.mux, commentsGet("account=2"))
	body := res.Body.String()

	// Assert
	if res.Code != http.StatusOK {
		t.Fatalf("status %d", res.Code)
	}
	for _, want := range []string{"Somchai", "Likely buyer", "สนใจค่ะ &lt;b&gt;ราคา&lt;/b&gt;?", "ส่งรายละเอียดทางแชทนะคะ",
		"Asks the price.", "days left to reply", "https://www.facebook.com/1111_2222", "Send private reply"} {
		if !strings.Contains(body, want) {
			t.Errorf("page lacks %q", want)
		}
	}
	if strings.Contains(body, "Other account secret") || strings.Contains(body, "<b>ราคา") {
		t.Error("page shows another account's comment or unescaped text")
	}
}

func TestComments_SendSendsTheEditedReply(t *testing.T) {
	// Arrange
	e := newCommentsEnv(t, true, true)
	c := e.waiting(t, 2, "c1", "ราคาเท่าไหร่", time.Now())

	// Act
	res := serve(e.mux, commentsPost(decide(c, 2, "send", "แก้ข้อความแล้วค่ะ")))

	// Assert
	got, _ := e.store.Get(context.Background(), 2, c.ID)
	if res.Code != http.StatusSeeOther || res.Header().Get("Location") != "/admin/comments?account=2&done=sent" {
		t.Fatalf("status %d location %q", res.Code, res.Header().Get("Location"))
	}
	if len(e.sender.sent) != 1 || e.sender.sent[0] != "c1|แก้ข้อความแล้วค่ะ" || got.Status != comments.StatusSent || got.DecidedBy != "admin password" {
		t.Fatalf("sent %v row %+v", e.sender.sent, got)
	}
}

func TestComments_DismissSendsNothing(t *testing.T) {
	// Arrange
	e := newCommentsEnv(t, true, true)
	c := e.waiting(t, 2, "c1", "ราคาเท่าไหร่", time.Now())

	// Act
	res := serve(e.mux, commentsPost(decide(c, 2, "dismiss", "")))

	// Assert
	got, _ := e.store.Get(context.Background(), 2, c.ID)
	page := serve(e.mux, commentsGet("account=2")).Body.String()
	if res.Code != http.StatusSeeOther || len(e.sender.sent) != 0 || got.Status != comments.StatusDismissed || !strings.Contains(page, "Dismissed") {
		t.Fatalf("status %d sent %v row %+v", res.Code, e.sender.sent, got)
	}
}

func TestComments_RefusedDecisionsChangeNothing(t *testing.T) {
	cases := map[string]struct {
		created  time.Time
		form     func(c comments.Comment) url.Values
		wantCode int
		wantText string
	}{
		"empty reply": {time.Now(), func(c comments.Comment) url.Values { return decide(c, 2, "send", "  ") },
			http.StatusUnprocessableEntity, "Write a reply"},
		"stale version": {time.Now(), func(c comments.Comment) url.Values {
			v := decide(c, 2, "send", "Hi")
			v.Set("version", strconv.Itoa(c.Version+1))
			return v
		}, http.StatusConflict, "changed after you opened"},
		"other account": {time.Now(), func(c comments.Comment) url.Values { return decide(c, 3, "send", "Hi") },
			http.StatusNotFound, "no longer waiting"},
		"too late": {time.Now().Add(-comments.ReplyWindow - time.Hour), func(c comments.Comment) url.Values { return decide(c, 2, "send", "Hi") },
			http.StatusConflict, "within 7 days"},
	}
	for name, tc := range cases {
		t.Run(name, func(t *testing.T) {
			// Arrange
			e := newCommentsEnv(t, true, true)
			c := e.waiting(t, 2, "c1", "ราคา", tc.created)

			// Act
			res := serve(e.mux, commentsPost(tc.form(c)))

			// Assert
			got, _ := e.store.Get(context.Background(), 2, c.ID)
			if res.Code != tc.wantCode || !strings.Contains(res.Body.String(), tc.wantText) || len(e.sender.sent) != 0 || got.Status != comments.StatusWaiting {
				t.Fatalf("status %d sent %v row status %s body has text %v", res.Code, e.sender.sent, got.Status, strings.Contains(res.Body.String(), tc.wantText))
			}
		})
	}
}

func TestComments_BadFormIsRejected(t *testing.T) {
	// Arrange
	e := newCommentsEnv(t, true, true)
	c := e.waiting(t, 2, "c1", "ราคา", time.Now())
	v := decide(c, 2, "approve", "Hi")

	// Act
	res := serve(e.mux, commentsPost(v))

	// Assert
	if res.Code != http.StatusBadRequest || len(e.sender.sent) != 0 {
		t.Fatalf("status %d", res.Code)
	}
}

func TestComments_NeedsTheAdminPasswordAndSameOrigin(t *testing.T) {
	// Arrange
	e := newCommentsEnv(t, true, true)
	c := e.waiting(t, 2, "c1", "ราคา", time.Now())
	wrong := commentsPost(decide(c, 2, "send", "Hi"))
	wrong.SetBasicAuth(Username, "wrong-password-123")
	cross := commentsPost(decide(c, 2, "send", "Hi"))
	cross.Header.Set("Sec-Fetch-Site", "cross-site")

	// Act
	wrongRes, crossRes := serve(e.mux, wrong), serve(e.mux, cross)

	// Assert
	got, _ := e.store.Get(context.Background(), 2, c.ID)
	if wrongRes.Code != http.StatusUnauthorized || crossRes.Code != http.StatusForbidden || len(e.sender.sent) != 0 || got.Status != comments.StatusWaiting {
		t.Fatalf("wrong %d cross %d sent %v", wrongRes.Code, crossRes.Code, e.sender.sent)
	}
}

func TestComments_OffAndSendingOff(t *testing.T) {
	// Arrange
	off := newCommentsEnv(t, false, false)
	noToken := newCommentsEnv(t, true, false)
	c := noToken.waiting(t, 1, "c1", "ราคา", time.Now())

	// Act
	offPage := serve(off.mux, commentsGet("")).Body.String()
	offPost := serve(off.mux, commentsPost(url.Values{"account": {"1"}, "id": {"1"}, "version": {"1"}, "decision": {"send"}}))
	noTokenPage := serve(noToken.mux, commentsGet("")).Body.String()
	noTokenPost := serve(noToken.mux, commentsPost(decide(c, 1, "send", "Hi")))

	// Assert
	if !strings.Contains(offPage, "Page comments are off") || offPost.Code != http.StatusServiceUnavailable {
		t.Fatalf("off page/post wrong: %d", offPost.Code)
	}
	if !strings.Contains(noTokenPage, "Sending is off") || !strings.Contains(noTokenPage, "disabled") || noTokenPost.Code != http.StatusServiceUnavailable {
		t.Fatalf("no token page/post wrong: %d", noTokenPost.Code)
	}
}

func TestComments_OversizedFormIsRefused(t *testing.T) {
	// Arrange
	e := newCommentsEnv(t, true, true)
	c := e.waiting(t, 2, "c1", "ราคา", time.Now())

	// Act
	res := serve(e.mux, commentsPost(decide(c, 2, "send", strings.Repeat("ก", 20000))))

	// Assert
	if res.Code != http.StatusBadRequest || len(e.sender.sent) != 0 {
		t.Fatalf("status %d sent %v", res.Code, e.sender.sent)
	}
}

func TestComments_DraftIsLabelledAsAnAISuggestion(t *testing.T) {
	// Arrange
	e := newCommentsEnv(t, true, true)
	e.waiting(t, 2, "c1", "ราคา", time.Now())

	// Act
	body := serve(e.mux, commentsGet("account=2")).Body.String()

	// Assert
	if !strings.Contains(body, "AI suggestion: check it before sending") {
		t.Fatal("draft not labelled")
	}
}

type fixedPost struct{ text string }

func (f fixedPost) Post(context.Context, string) (comments.Post, error) {
	return comments.Post{Text: f.text}, nil
}

func TestComments_CardShowsThePostTheCommentIsOn(t *testing.T) {
	// Arrange: the owner must see which post "สนใจ" was about.
	e := newCommentsEnv(t, true, true)
	e.waiting(t, 2, "c1", "สนใจครับ", time.Now())
	h := &Handler{Password: pw, Timeout: time.Second, Logger: slog.New(slog.NewJSONHandler(io.Discard, nil)),
		Comments: &comments.Queue{Store: e.store, Posts: fixedPost{text: "ทุนนวัตกรรมพลังงาน <script>x</script>"}}}
	h.Store, _ = settings.Open(t.TempDir()+"/s.json", settings.LLM{})
	h.Switch = &llm.Switch{}
	mux := http.NewServeMux()
	h.Routes(mux)

	// Act
	body := serve(mux, commentsGet("account=2")).Body.String()

	// Assert
	if !strings.Contains(body, "On the post") || !strings.Contains(body, "ทุนนวัตกรรมพลังงาน &lt;script&gt;") {
		t.Fatalf("post snippet missing or unescaped")
	}
}
