package chatwoot

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/memory"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

type captured struct {
	path, token string
	body        map[string]any
}

func newServer(t *testing.T, status int, got *captured) *httptest.Server {
	t.Helper()
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		got.path = r.URL.Path
		got.token = r.Header.Get("api_access_token")
		_ = json.NewDecoder(r.Body).Decode(&got.body)
		w.WriteHeader(status)
		_, _ = w.Write([]byte(`{"error":"nope"}`))
	}))
	t.Cleanup(srv.Close)
	return srv
}

func TestSendMessage_PostsPublicOutgoing(t *testing.T) {
	// Arrange
	var got captured
	srv := newServer(t, http.StatusOK, &got)
	c := New(srv.URL, "bot-token", nil)

	// Act
	err := c.SendMessage(context.Background(), 1, 7, "hello")

	// Assert
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got.path != "/api/v1/accounts/1/conversations/7/messages" || got.token != "bot-token" {
		t.Errorf("path=%q token=%q", got.path, got.token)
	}
	if got.body["content"] != "hello" || got.body["private"] != false || got.body["message_type"] != "outgoing" {
		t.Errorf("body = %v", got.body)
	}
}

func TestSendPrivateNote_SetsPrivate(t *testing.T) {
	// Arrange
	var got captured
	c := New(newServer(t, http.StatusOK, &got).URL, "t", nil)

	// Act
	err := c.SendPrivateNote(context.Background(), 1, 7, "note")

	// Assert
	if err != nil || got.body["private"] != true {
		t.Errorf("err=%v body=%v", err, got.body)
	}
}

func TestHandoff_TogglesStatusOpen(t *testing.T) {
	// Arrange
	var got captured
	c := New(newServer(t, http.StatusOK, &got).URL, "t", nil)

	// Act
	err := c.Handoff(context.Background(), 2, 5)

	// Assert
	if err != nil || got.path != "/api/v1/accounts/2/conversations/5/toggle_status" || got.body["status"] != "open" {
		t.Errorf("err=%v path=%q body=%v", err, got.path, got.body)
	}
}

func TestSetTyping_SendsOnOff(t *testing.T) {
	// Arrange
	var got captured
	c := New(newServer(t, http.StatusOK, &got).URL, "t", nil)

	// Act
	err := c.SetTyping(context.Background(), 1, 7, false)

	// Assert
	if err != nil || got.path != "/api/v1/accounts/1/conversations/7/toggle_typing_status" || got.body["typing_status"] != "off" {
		t.Errorf("err=%v path=%q body=%v", err, got.path, got.body)
	}
}

func TestPost_ReturnsAPIErrorOnNon2xx(t *testing.T) {
	// Arrange
	var got captured
	c := New(newServer(t, http.StatusUnauthorized, &got).URL, "bad", nil)

	// Act
	err := c.SendMessage(context.Background(), 1, 7, "x")

	// Assert
	var apiErr *APIError
	if !errors.As(err, &apiErr) || apiErr.Status != http.StatusUnauthorized {
		t.Fatalf("expected APIError 401, got %v", err)
	}
}

func TestSetConversationAttributes_MergesOnly(t *testing.T) {
	// Arrange
	var got captured
	c := New(newServer(t, http.StatusOK, &got).URL, "t", nil)

	// Act
	err := c.SetConversationAttributes(context.Background(), 1, 7, map[string]string{"customer_email": "a@gmail.com"})

	// Assert
	attrs, _ := got.body["custom_attributes"].(map[string]any)
	if err != nil || got.path != "/api/v1/accounts/1/conversations/7/custom_attributes" || got.body["merge"] != true || attrs["customer_email"] != "a@gmail.com" {
		t.Fatalf("err=%v path=%q body=%v", err, got.path, got.body)
	}
}

func TestConversationStatus(t *testing.T) {
	// Arrange
	var path, token string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		path, token = r.URL.Path, r.Header.Get("api_access_token")
		if r.Method != http.MethodGet {
			w.WriteHeader(http.StatusMethodNotAllowed)
			return
		}
		_, _ = w.Write([]byte(`{"id":7,"status":"open","meta":{}}`))
	}))
	defer srv.Close()
	c := New(srv.URL, "bot-token", nil)

	// Act
	status, err := c.ConversationStatus(context.Background(), 1, 7)

	// Assert
	if err != nil || status != "open" || path != "/api/v1/accounts/1/conversations/7" || token != "bot-token" {
		t.Fatalf("status=%q err=%v path=%q token=%q", status, err, path, token)
	}
}

func TestConversationStatusError(t *testing.T) {
	// Arrange
	var got captured
	srv := newServer(t, http.StatusNotFound, &got)
	c := New(srv.URL, "bot-token", nil)

	// Act
	_, err := c.ConversationStatus(context.Background(), 1, 7)

	// Assert
	var apiErr *APIError
	if !errors.As(err, &apiErr) || apiErr.Status != http.StatusNotFound {
		t.Fatalf("err = %v, want APIError 404", err)
	}
}

func TestRecentTurns_KeepsTheChatSkipsNotesAndActivity(t *testing.T) {
	// Arrange: Chatwoot's message list, oldest first, as the API returns it.
	var path, token string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		path, token = r.URL.Path, r.Header.Get("api_access_token")
		_, _ = w.Write([]byte(`{"payload":[
			{"id":1,"message_type":0,"private":false,"content":"ราคาเท่าไหร่"},
			{"id":2,"message_type":1,"private":false,"content":"3,900 บาทครับ","sender":{"type":"agent_bot"}},
			{"id":3,"message_type":1,"private":true,"content":"🤖 สรุปจากบอท ...","sender":{"type":"agent_bot"}},
			{"id":4,"message_type":2,"private":false,"content":"Conversation was reopened"},
			{"id":5,"message_type":1,"private":false,"content":"แอดมินตอบจาก Messenger"},
			{"id":6,"message_type":0,"private":false,"content":"","attachments":[{"file_type":"image"}]},
			{"id":7,"message_type":0,"private":false,"content":"ข้อความปัจจุบัน"}
		]}`))
	}))
	defer srv.Close()
	r := NewReader(srv.URL, "reader-token", nil)

	// Act
	turns, err := r.RecentTurns(context.Background(), 1, 76, 7)

	// Assert
	if err != nil || path != "/api/v1/accounts/1/conversations/76/messages" || token != "reader-token" {
		t.Fatalf("err=%v path=%q token=%q", err, path, token)
	}
	want := []struct{ role, content string }{
		{"user", "ราคาเท่าไหร่"},
		{"assistant", "3,900 บาทครับ"},
		{"assistant", "แอดมินตอบจาก Messenger"},
		{"user", "[The customer sent a file]"},
	}
	if len(turns) != len(want) {
		t.Fatalf("turns = %+v, want %d (no private notes, no activity, not the current message)", turns, len(want))
	}
	for i, w := range want {
		if turns[i].Role != w.role || turns[i].Content != w.content {
			t.Errorf("turn %d = %+v, want %s %q", i, turns[i], w.role, w.content)
		}
	}
}

func TestRecentTurns_ErrorStatus(t *testing.T) {
	// Arrange
	var got captured
	srv := newServer(t, http.StatusUnauthorized, &got)
	r := NewReader(srv.URL, "wrong", nil)

	// Act
	_, err := r.RecentTurns(context.Background(), 1, 76, 0)

	// Assert
	var apiErr *APIError
	if !errors.As(err, &apiErr) || apiErr.Status != http.StatusUnauthorized {
		t.Fatalf("err = %v, want APIError 401", err)
	}
}

func TestReaderStaffOpenCountAndAssignee(t *testing.T) {
	// Arrange
	var filterBody map[string]any
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/api/v1/profile":
			_, _ = w.Write([]byte(`{"id":9,"name":"AI Reader"}`))
		case "/api/v1/accounts/1/inbox_members/2":
			_, _ = w.Write([]byte(`{"payload":[{"id":5,"name":"Newk","availability_status":"online"},{"id":9,"name":"AI Reader","availability_status":"offline"}]}`))
		case "/api/v1/accounts/1/conversations/filter":
			_ = json.NewDecoder(r.Body).Decode(&filterBody)
			_, _ = w.Write([]byte(`{"meta":{"all_count":4}}`))
		case "/api/v1/accounts/1/conversations/76":
			_, _ = w.Write([]byte(`{"id":76,"meta":{"assignee":{"id":5},"assignee_type":"User"}}`))
		case "/api/v1/accounts/1/conversations/77":
			_, _ = w.Write([]byte(`{"id":77,"meta":{}}`))
		case "/api/v1/accounts/1/conversations/78":
			// A chat the bot handles: Chatwoot reports the agent bot as assignee,
			// and its id can equal a user's id.
			_, _ = w.Write([]byte(`{"id":78,"meta":{"assignee":{"id":5,"name":"AI Assistant"},"assignee_type":"AgentBot"}}`))
		default:
			http.NotFound(w, r)
		}
	}))
	defer srv.Close()
	r := NewReader(srv.URL, "reader-token", nil)
	ctx := context.Background()

	// Act
	staff, errStaff := r.InboxStaff(ctx, 1, 2)
	open, errOpen := r.OpenCount(ctx, 1, 5)
	assigned, errA := r.Assignee(ctx, 1, 76)
	none, errN := r.Assignee(ctx, 1, 77)
	bot, errB := r.Assignee(ctx, 1, 78)

	// Assert
	if errStaff != nil || len(staff) != 2 || !staff[0].Online || staff[1].Online || staff[0].ID != 5 || staff[0].Reader || !staff[1].Reader {
		t.Errorf("staff = %+v err=%v", staff, errStaff)
	}
	if errOpen != nil || open != 4 {
		t.Errorf("open = %d err=%v", open, errOpen)
	}
	if fb := fmt.Sprint(filterBody); !strings.Contains(fb, "assignee_id") || !strings.Contains(fb, "open") {
		t.Errorf("filter must ask for open conversations of that assignee, sent %v", filterBody)
	}
	if errB != nil || bot != 0 {
		t.Errorf("an agent bot assignee must not count as a person, got %d (%v)", bot, errB)
	}
	if errA != nil || assigned != 5 || errN != nil || none != 0 {
		t.Errorf("assignee = %d (%v), none = %d (%v)", assigned, errA, none, errN)
	}
}

func TestAddLabelKeepsOtherLabelsAndSkipsDuplicates(t *testing.T) {
	// Arrange
	var posted []map[string]any
	labels := `["vip"]`
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodGet {
			_, _ = w.Write([]byte(`{"payload":` + labels + `}`))
			return
		}
		var b map[string]any
		_ = json.NewDecoder(r.Body).Decode(&b)
		posted = append(posted, b)
		_, _ = w.Write([]byte(`{}`))
	}))
	defer srv.Close()
	c := New(srv.URL, "bot-token", nil)

	// Act
	err1 := c.AddLabel(context.Background(), 1, 7, "bot-handoff")
	labels = `["vip","bot-handoff"]`
	err2 := c.AddLabel(context.Background(), 1, 7, "bot-handoff")

	// Assert
	if err1 != nil || err2 != nil || len(posted) != 1 {
		t.Fatalf("errs %v %v, posts %d (want 1: no repost when already labelled)", err1, err2, len(posted))
	}
	if got := fmt.Sprint(posted[0]["labels"]); got != "[vip bot-handoff]" {
		t.Errorf("labels sent = %s, want the existing ones kept", got)
	}
}

func TestAssignPostsAssignee(t *testing.T) {
	// Arrange
	var got captured
	srv := newServer(t, http.StatusOK, &got)
	c := New(srv.URL, "bot-token", nil)

	// Act
	err := c.Assign(context.Background(), 1, 7, 5)

	// Assert
	if err != nil || got.path != "/api/v1/accounts/1/conversations/7/assignments" || got.body["assignee_id"] != float64(5) {
		t.Errorf("err=%v path=%q body=%v", err, got.path, got.body)
	}
}

func TestRecentTurns_MarksPageMessagesSentBeforeTheBotSpoke(t *testing.T) {
	// Arrange: an ad's welcome message and an Instant Reply (echoes, before the
	// bot's first reply), then the bot, then an admin echo from Messenger.
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, _ = w.Write([]byte(`{"payload":[
			{"id":1,"message_type":1,"private":false,"content":"สนใจคอร์สไหมคะ","content_attributes":{"external_echo":true}},
			{"id":2,"message_type":0,"private":false,"content":"ราคาเท่าไหร่?"},
			{"id":3,"message_type":1,"private":false,"content":"ขอบคุณที่ทักมานะคะ","content_attributes":{"external_echo":true}},
			{"id":4,"message_type":1,"private":false,"content":"3,900 บาทครับ","sender":{"type":"agent_bot"}},
			{"id":5,"message_type":1,"private":false,"content":"แอดมินตอบเองครับ","content_attributes":{"external_echo":true}}
		]}`))
	}))
	defer srv.Close()
	r := NewReader(srv.URL, "reader-token", nil)

	// Act
	turns, err := r.RecentTurns(context.Background(), 1, 76, 0)

	// Assert
	want := []string{
		memory.PageMessagePrefix + "สนใจคอร์สไหมคะ",
		"ราคาเท่าไหร่?",
		memory.PageMessagePrefix + "ขอบคุณที่ทักมานะคะ",
		"3,900 บาทครับ",
		"แอดมินตอบเองครับ",
	}
	if err != nil || len(turns) != len(want) {
		t.Fatalf("turns = %+v err=%v", turns, err)
	}
	for i, w := range want {
		if turns[i].Content != w {
			t.Errorf("turn %d = %q, want %q", i, turns[i].Content, w)
		}
	}
}
