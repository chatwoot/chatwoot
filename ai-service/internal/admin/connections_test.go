package admin

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/mcp"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/oauth"
)

type memTokens struct{ tokens []mcp.Token }

func (m *memTokens) Create(_ context.Context, acct int64, name string, w bool, ttl time.Duration) (string, mcp.Token, error) {
	if strings.TrimSpace(name) == "" {
		return "", mcp.Token{}, errors.New("a token needs a name")
	}
	t := mcp.Token{ID: int64(len(m.tokens) + 1), AccountID: acct, Name: name, CanWrite: w, CreatedAt: time.Now()}
	if ttl > 0 {
		t.ExpiresAt = time.Now().Add(ttl)
	}
	m.tokens = append(m.tokens, t)
	return mcp.TokenPrefix + "SECRET" + name, t, nil
}
func (m *memTokens) Lookup(context.Context, string) (mcp.Token, error) {
	return mcp.Token{}, mcp.ErrInvalidToken
}
func (m *memTokens) List(_ context.Context, acct int64) ([]mcp.Token, error) {
	var out []mcp.Token
	for _, t := range m.tokens {
		if t.AccountID == acct {
			out = append(out, t)
		}
	}
	return out, nil
}
func (m *memTokens) Revoke(_ context.Context, acct, id int64) error {
	for i, t := range m.tokens {
		if t.ID == id && t.AccountID == acct && t.RevokedAt.IsZero() {
			m.tokens[i].RevokedAt = time.Now()
			return nil
		}
	}
	return mcp.ErrInvalidToken
}

func connPost(v url.Values) *http.Request {
	r := httptest.NewRequest(http.MethodPost, "/admin/connections", strings.NewReader(v.Encode()))
	r.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	r.Header.Set("Sec-Fetch-Site", "same-origin")
	r.SetBasicAuth(Username, pw)
	return r
}

func TestConnections_CreateShowsTokenOnce(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	mt := &memTokens{}
	e.h.Tokens, e.h.MCPURL = mt, "https://ai-admin.example/mcp"

	// Act
	created := e.do(connPost(url.Values{"action": {"create"}, "account": {"1"}, "name": {"Claude"}}))
	again := httptest.NewRequest(http.MethodGet, "/admin/connections?account=1", nil)
	again.SetBasicAuth(Username, pw)
	later := e.do(again).Body.String()

	// Assert
	body := created.Body.String()
	if created.Code != http.StatusOK || !strings.Contains(body, "aisvc_mcp_SECRETClaude") ||
		!strings.Contains(body, "claude mcp add --transport http ai-knowledge https://ai-admin.example/mcp") {
		t.Fatalf("create page: code=%d", created.Code)
	}
	if created.Header().Get("Cache-Control") != "no-store" {
		t.Error("the page showing a token must not be cached")
	}
	if strings.Contains(later, "SECRET") || !strings.Contains(later, "Claude") || !strings.Contains(later, "Read only") {
		t.Fatal("token shown again, or not listed as read-only")
	}
	if len(mt.tokens) != 1 || mt.tokens[0].CanWrite || mt.tokens[0].ExpiresAt.Before(time.Now().Add(89*24*time.Hour)) {
		t.Fatalf("tokens = %+v, want one read-only token expiring in 90 days by default", mt.tokens)
	}
}

func TestConnections_RevokeOnlyOwnAccount(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	mt := &memTokens{tokens: []mcp.Token{{ID: 1, AccountID: 2, Name: "theirs", CreatedAt: time.Now()}}}
	e.h.Tokens = mt

	// Act
	cross := e.do(connPost(url.Values{"action": {"revoke"}, "account": {"1"}, "id": {"1"}}))
	own := e.do(connPost(url.Values{"action": {"revoke"}, "account": {"2"}, "id": {"1"}}))

	// Assert
	if cross.Code != http.StatusUnprocessableEntity || own.Code != http.StatusSeeOther || mt.tokens[0].RevokedAt.IsZero() {
		t.Fatalf("cross=%d own=%d", cross.Code, own.Code)
	}
}

func TestConnections_RequiresAuthAndSameOrigin(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	mt := &memTokens{}
	e.h.Tokens = mt
	noAuth := connPost(url.Values{"action": {"create"}, "account": {"1"}, "name": {"x"}})
	noAuth.Header.Del("Authorization")
	cross := connPost(url.Values{"action": {"create"}, "account": {"1"}, "name": {"x"}})
	cross.Header.Set("Sec-Fetch-Site", "cross-site")

	// Act
	a, c := e.do(noAuth), e.do(cross)

	// Assert
	if a.Code != http.StatusUnauthorized || c.Code != http.StatusForbidden || len(mt.tokens) != 0 {
		t.Fatalf("noauth=%d cross=%d tokens=%d", a.Code, c.Code, len(mt.tokens))
	}
}

type memApps struct {
	oauth.Store
	team    []oauth.Member
	removed []string
}

func (m *memApps) Grants(context.Context, int64) ([]oauth.Grant, error) {
	return []oauth.Grant{{ID: 1, ClientName: "Claude", ApprovedBy: "somchai@example.com", CreatedAt: time.Now()}}, nil
}
func (m *memApps) Team(_ context.Context, acct int64) ([]oauth.Member, error) {
	var out []oauth.Member
	for _, t := range m.team {
		if t.AccountID == acct {
			out = append(out, t)
		}
	}
	return out, nil
}
func (m *memApps) AddMember(_ context.Context, mm oauth.Member) error {
	m.team = append(m.team, mm)
	return nil
}
func (m *memApps) RemoveMember(_ context.Context, email string, acct int64) error {
	m.removed = append(m.removed, email)
	return nil
}

func TestTeam_AddListRemove(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	apps := &memApps{}
	e.h.Tokens, e.h.Apps, e.h.TeamSignIn, e.h.MCPURL = &memTokens{}, apps, true, "https://mcp.example.com/mcp"

	// Act
	added := e.do(connPost(url.Values{"action": {"add_member"}, "account": {"1"}, "email": {" Somchai@Example.com "}, "member_access": {"write"}}))
	bad := e.do(connPost(url.Values{"action": {"add_member"}, "account": {"1"}, "email": {"not-an-email"}}))
	page := httptest.NewRequest(http.MethodGet, "/admin/connections?account=1", nil)
	page.SetBasicAuth(Username, pw)
	body := e.do(page).Body.String()
	removed := e.do(connPost(url.Values{"action": {"remove_member"}, "account": {"1"}, "email": {"somchai@example.com"}}))

	// Assert
	if added.Code != http.StatusSeeOther || len(apps.team) != 1 || apps.team[0].Email != "somchai@example.com" || !apps.team[0].CanWrite {
		t.Fatalf("add: code=%d team=%+v", added.Code, apps.team)
	}
	if bad.Code != http.StatusUnprocessableEntity || len(apps.team) != 1 {
		t.Fatalf("invalid email accepted: %d", bad.Code)
	}
	if !strings.Contains(body, "Team for account 1") || !strings.Contains(body, "somchai@example.com") || !strings.Contains(body, "Connected by") {
		t.Fatal("team or connected-by missing from the page")
	}
	if removed.Code != http.StatusSeeOther || len(apps.removed) != 1 {
		t.Fatalf("remove: %d", removed.Code)
	}
}

func TestTeam_HiddenAndRefusedWithoutAccess(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	apps := &memApps{}
	e.h.Tokens, e.h.Apps, e.h.MCPURL = &memTokens{}, apps, "https://mcp.example.com/mcp"

	// Act
	rec := e.do(connPost(url.Values{"action": {"add_member"}, "account": {"1"}, "email": {"a@example.com"}}))
	page := httptest.NewRequest(http.MethodGet, "/admin/connections?account=1", nil)
	page.SetBasicAuth(Username, pw)
	body := e.do(page).Body.String()

	// Assert
	if rec.Code != http.StatusBadRequest || len(apps.team) != 0 || strings.Contains(body, "Team for account") {
		t.Fatalf("code=%d team=%d", rec.Code, len(apps.team))
	}
}
