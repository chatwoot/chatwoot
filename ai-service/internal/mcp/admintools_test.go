package mcp

import (
	"context"
	"encoding/json"
	"strings"
	"testing"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/audit"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/profile"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/websync"
)

// --- fakes for the profile, sources and change-history tools ---

type memProfiles struct {
	byAcct map[int64]profile.Profile
	saves  int
}

func (m *memProfiles) Get(_ context.Context, acct int64) (profile.Profile, error) {
	if p, ok := m.byAcct[acct]; ok {
		return p, nil
	}
	return profile.Profile{AccountID: acct}, nil
}
func (m *memProfiles) Save(_ context.Context, p profile.Profile) error {
	if err := p.Validate(); err != nil {
		return err
	}
	m.saves++
	m.byAcct[p.AccountID] = p
	return nil
}

type memSources struct {
	srcs []websync.Source
	busy bool
}

func (m *memSources) List(_ context.Context, acct int64) ([]websync.Source, error) {
	var out []websync.Source
	for _, s := range m.srcs {
		if s.AccountID == acct {
			out = append(out, s)
		}
	}
	return out, nil
}
func (m *memSources) Get(_ context.Context, acct, id int64) (websync.Source, error) {
	for _, s := range m.srcs {
		if s.AccountID == acct && s.ID == id {
			return s, nil
		}
	}
	return websync.Source{}, websync.ErrNotFound
}
func (m *memSources) ClaimOne(ctx context.Context, acct, id int64) (websync.Source, error) {
	if m.busy {
		return websync.Source{}, websync.ErrBusy
	}
	return m.Get(ctx, acct, id)
}
func (m *memSources) SetInterval(_ context.Context, acct, id int64, hours int) error {
	for i, s := range m.srcs {
		if s.AccountID == acct && s.ID == id {
			m.srcs[i].IntervalHours = hours
			return nil
		}
	}
	return websync.ErrNotFound
}

type fakeChecker struct {
	checked, later []int64
}

func (f *fakeChecker) Check(_ context.Context, s websync.Source) (websync.Outcome, error) {
	f.checked = append(f.checked, s.ID)
	return websync.Unchanged, nil
}
func (f *fakeChecker) CheckLater(_ context.Context, s websync.Source) {
	f.later = append(f.later, s.ID)
}

type memEvents struct {
	events []audit.Event
	fail   bool
}

func (m *memEvents) Record(_ context.Context, e audit.Event) error {
	if m.fail {
		return context.DeadlineExceeded
	}
	m.events = append(m.events, e)
	return nil
}
func (m *memEvents) Recent(_ context.Context, acct int64, limit int) ([]audit.Event, error) {
	var out []audit.Event
	for i := len(m.events) - 1; i >= 0 && len(out) < limit; i-- {
		e := m.events[i]
		if e.AccountID == acct || e.AccountID == 0 {
			e.Global = e.AccountID == 0
			e.AccountID = acct
			out = append(out, e)
		}
	}
	return out, nil
}

type adminEnv struct {
	*env
	profiles *memProfiles
	sources  *memSources
	checker  *fakeChecker
	events   *memEvents
}

func newAdminEnv() *adminEnv {
	e := &adminEnv{env: newEnv(),
		profiles: &memProfiles{byAcct: map[int64]profile.Profile{
			1: {AccountID: 1, BusinessName: "John Auto Cut", Rules: "Never promise a price.", Features: profile.Features{Voice: true}},
			2: {AccountID: 2, BusinessName: "Other shop", Rules: "secret rule"},
		}},
		sources: &memSources{srcs: []websync.Source{
			{ID: 5, AccountID: 1, Kind: websync.KindFeed, URL: "https://docs.google.com/spreadsheets/d/abc/export?format=csv&gid=1", Title: "Page", IntervalHours: 24, Status: "ok", Items: 9},
			{ID: 7, AccountID: 1, Kind: websync.KindPage, URL: "https://example.com/faq", Title: "FAQ", IntervalHours: 6, Status: "ok"},
			{ID: 9, AccountID: 2, Kind: websync.KindPage, URL: "https://other.example/secret", Title: "Other", IntervalHours: 6},
		}},
		checker: &fakeChecker{}, events: &memEvents{},
	}
	e.srv.Profiles, e.srv.Sources, e.srv.Checker, e.srv.Events = e.profiles, e.sources, e.checker, e.events
	return e
}

func decodeResult(t *testing.T, res map[string]any, v any) {
	t.Helper()
	if isErr(res) {
		t.Fatalf("tool error: %s", text(res))
	}
	if err := json.Unmarshal([]byte(text(res)), v); err != nil {
		t.Fatalf("result %q: %v", text(res), err)
	}
}

// --- tests ---

func TestAdminTools_HiddenWithoutStoresAndForReadOnly(t *testing.T) {
	// Arrange
	bare, full := newEnv(), newAdminEnv()
	names := func(e *env, tok string) string {
		_, out := e.rpc(tok, "tools/list", nil)
		var n []string
		for _, t := range out["result"].(map[string]any)["tools"].([]any) {
			n = append(n, t.(map[string]any)["name"].(string))
		}
		return "," + strings.Join(n, ",") + ","
	}

	// Act
	bareRW, fullRW, fullRO := names(bare, rw), names(full.env, rw), names(full.env, ro)

	// Assert
	for _, n := range []string{"get_profile", "update_profile", "list_sources", "sync_source", "set_source_schedule", "list_changes"} {
		if strings.Contains(bareRW, ","+n+",") {
			t.Errorf("%s listed without its store: %s", n, bareRW)
		}
		if !strings.Contains(fullRW, ","+n+",") {
			t.Errorf("%s missing for a write token: %s", n, fullRW)
		}
	}
	for _, n := range []string{"update_profile", "sync_source", "set_source_schedule"} {
		if strings.Contains(fullRO, ","+n+",") {
			t.Errorf("write tool %s listed for a read-only token", n)
		}
	}
	for _, n := range []string{"get_profile", "list_sources", "list_changes"} {
		if !strings.Contains(fullRO, ","+n+",") {
			t.Errorf("read tool %s missing for a read-only token", n)
		}
	}
	if res := bare.call(rw, "get_profile", map[string]any{}); !isErr(res) && res != nil {
		t.Errorf("get_profile without a store = %v", res)
	}
}

func TestAdminTools_GetProfileStaysInAccount(t *testing.T) {
	// Arrange
	e := newAdminEnv()

	// Act
	var got map[string]any
	decodeResult(t, e.call(ro, "get_profile", map[string]any{}), &got)
	forged := e.call(ro, "get_profile", map[string]any{"account_id": 2})

	// Assert
	if got["business_name"] != "John Auto Cut" || got["rules"] != "Never promise a price." || got["voice_notes"] != true {
		t.Fatalf("profile = %v", got)
	}
	if strings.Contains(text(forged), "secret rule") || !isErr(forged) {
		t.Fatalf("account_id argument accepted: %v", forged)
	}
}

func TestAdminTools_UpdateProfileChangesOnlyGivenFields(t *testing.T) {
	// Arrange
	e := newAdminEnv()

	// Act
	var out map[string]any
	decodeResult(t, e.call(rw, "update_profile", map[string]any{"tone": "  Friendly, short.\r\n", "images": true}), &out)

	// Assert
	p := e.profiles.byAcct[1]
	if p.Tone != "Friendly, short." || !p.Features.Images || !p.Features.Voice || p.Rules != "Never promise a price." || p.BusinessName != "John Auto Cut" {
		t.Fatalf("profile = %+v", p)
	}
	if e.profiles.byAcct[2].Rules != "secret rule" {
		t.Fatal("another account's profile changed")
	}
	if len(e.events.events) != 1 {
		t.Fatalf("events = %+v", e.events.events)
	}
	ev := e.events.events[0]
	before, _ := ev.Before.(profileView)
	if ev.AccountID != 1 || ev.Actor != "claude (AI tool)" || ev.Action != "business profile saved" ||
		!strings.Contains(ev.Summary, "tone") || !strings.Contains(ev.Summary, "images") || before.Tone != "" || before.Rules != "Never promise a price." {
		t.Fatalf("event = %+v", ev)
	}
	if out["result"] != "saved" {
		t.Fatalf("out = %v", out)
	}
}

func TestAdminTools_UpdateProfileRefusals(t *testing.T) {
	cases := map[string]struct {
		tok  string
		args map[string]any
		fail bool // history store fails
		want string
	}{
		"read-only token":   {ro, map[string]any{"tone": "x"}, false, "read-only"},
		"no fields":         {rw, map[string]any{}, false, "give at least one field"},
		"too long":          {rw, map[string]any{"rules": strings.Repeat("ก", profile.MaxFieldRunes+1)}, false, "limit"},
		"nul byte":          {rw, map[string]any{"about": "a\x00b"}, false, "UTF-8"},
		"forged account":    {rw, map[string]any{"account_id": 2, "rules": "x"}, false, "invalid arguments"},
		"history not saved": {rw, map[string]any{"rules": "x"}, true, "not saved"},
	}
	for name, c := range cases {
		t.Run(name, func(t *testing.T) {
			// Arrange
			e := newAdminEnv()
			e.events.fail = c.fail
			want := e.profiles.byAcct[1]

			// Act
			res := e.call(c.tok, "update_profile", c.args)

			// Assert
			if !isErr(res) || !strings.Contains(text(res), c.want) {
				t.Fatalf("res = %v, want error containing %q", text(res), c.want)
			}
			if e.profiles.saves != 0 || e.profiles.byAcct[1] != want || e.profiles.byAcct[2].Rules != "secret rule" {
				t.Fatal("a refused update changed a profile")
			}
			if !c.fail && len(e.events.events) != 0 {
				t.Fatal("a refused update was recorded")
			}
		})
	}
}

func TestAdminTools_UpdateProfileUnchangedIsNotSaved(t *testing.T) {
	// Arrange
	e := newAdminEnv()

	// Act
	var out map[string]any
	decodeResult(t, e.call(rw, "update_profile", map[string]any{"rules": "Never promise a price.", "voice_notes": true}), &out)

	// Assert
	if out["result"] != "unchanged" || e.profiles.saves != 0 || len(e.events.events) != 0 {
		t.Fatalf("out=%v saves=%d events=%d", out, e.profiles.saves, len(e.events.events))
	}
}

func TestAdminTools_ListSourcesHidesQueryAndOtherAccounts(t *testing.T) {
	// Arrange
	e := newAdminEnv()

	// Act
	res := e.call(ro, "list_sources", map[string]any{})
	var out struct {
		Count   int              `json:"count"`
		Sources []map[string]any `json:"sources"`
	}
	decodeResult(t, res, &out)

	// Assert
	if out.Count != 2 || strings.Contains(text(res), "other.example") {
		t.Fatalf("sources = %s", text(res))
	}
	if strings.Contains(text(res), "gid=") || strings.Contains(text(res), "format=csv") {
		t.Fatalf("query string leaked: %s", text(res))
	}
	feed := out.Sources[0]
	if feed["kind"] != "feed" || feed["address"] != "docs.google.com/spreadsheets/d/abc/export" || feed["rows"] != float64(9) || feed["schedule_hours"] != float64(24) {
		t.Fatalf("feed = %v", feed)
	}
}

func TestAdminTools_SyncSource(t *testing.T) {
	// Arrange
	e := newAdminEnv()

	// Act
	feed := e.call(rw, "sync_source", map[string]any{"id": 5})
	page := e.call(rw, "sync_source", map[string]any{"id": 7})
	other := e.call(rw, "sync_source", map[string]any{"id": 9})
	readOnly := e.call(ro, "sync_source", map[string]any{"id": 7})
	e.sources.busy = true
	busy := e.call(rw, "sync_source", map[string]any{"id": 7})

	// Assert
	if isErr(feed) || !strings.Contains(text(feed), "started") || len(e.checker.later) != 1 || e.checker.later[0] != 5 {
		t.Fatalf("feed: %s later=%v", text(feed), e.checker.later)
	}
	if isErr(page) || !strings.Contains(text(page), string(websync.Unchanged)) || len(e.checker.checked) != 1 || e.checker.checked[0] != 7 {
		t.Fatalf("page: %s checked=%v", text(page), e.checker.checked)
	}
	if !isErr(other) || !strings.Contains(text(other), "no source") {
		t.Fatalf("other account's source: %s", text(other))
	}
	if !isErr(readOnly) || !isErr(busy) || !strings.Contains(text(busy), "being checked") {
		t.Fatalf("readOnly=%s busy=%s", text(readOnly), text(busy))
	}
	if len(e.checker.checked) != 1 || len(e.checker.later) != 1 {
		t.Fatal("a refused sync ran a check")
	}
}

func TestAdminTools_SetSourceSchedule(t *testing.T) {
	// Arrange
	e := newAdminEnv()

	// Act
	ok := e.call(rw, "set_source_schedule", map[string]any{"id": 7, "hours": 24})
	bad := e.call(rw, "set_source_schedule", map[string]any{"id": 7, "hours": 2})
	other := e.call(rw, "set_source_schedule", map[string]any{"id": 9, "hours": 1})
	e.events.fail = true
	noHistory := e.call(rw, "set_source_schedule", map[string]any{"id": 5, "hours": 1})

	// Assert
	if isErr(ok) || e.sources.srcs[1].IntervalHours != 24 {
		t.Fatalf("ok: %s src=%+v", text(ok), e.sources.srcs[1])
	}
	if !isErr(bad) || !isErr(other) || e.sources.srcs[2].IntervalHours != 6 {
		t.Fatalf("bad=%s other=%s", text(bad), text(other))
	}
	if !isErr(noHistory) || e.sources.srcs[0].IntervalHours != 24 {
		t.Fatalf("schedule changed without history: %s", text(noHistory))
	}
	if len(e.events.events) != 1 || e.events.events[0].Action != "web page schedule changed" || e.events.events[0].Summary != "FAQ: 24 h" {
		t.Fatalf("events = %+v", e.events.events)
	}
}

func TestAdminTools_ListChangesSkipsServiceWide(t *testing.T) {
	// Arrange
	e := newAdminEnv()
	at := time.Date(2026, 11, 8, 2, 30, 0, 0, time.UTC)
	e.events.events = []audit.Event{
		{AccountID: 1, Actor: "john@example.com", Action: "data feed added", Summary: "docs.google.com", At: at},
		{AccountID: 0, Actor: "admin password", Action: "providers saved", Summary: "chat api.openai.com", At: at},
		{AccountID: 2, Actor: "x", Action: "token created", Summary: "other account", At: at},
	}

	// Act
	res := e.call(ro, "list_changes", map[string]any{"limit": 10})
	tooMany := e.call(ro, "list_changes", map[string]any{"limit": 500})

	// Assert
	if isErr(res) || !strings.Contains(text(res), "data feed added") || strings.Contains(text(res), "providers saved") || strings.Contains(text(res), "other account") {
		t.Fatalf("changes = %s", text(res))
	}
	if !isErr(tooMany) {
		t.Fatalf("limit 500 accepted: %s", text(tooMany))
	}
}
