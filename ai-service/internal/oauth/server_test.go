package oauth

import (
	"context"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"html"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/cfaccess"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/ratelimit"
)

// --- in-memory store ---

type mem struct {
	team    []Member
	clients map[string]Client
	codes   map[string]Code
	grants  map[int64]*memGrant
	issued  []Grant
}

type memGrant struct {
	Grant
	refresh, prev string
}

func newMem() *mem {
	return &mem{clients: map[string]Client{}, codes: map[string]Code{}, grants: map[int64]*memGrant{}}
}

func (m *mem) RegisterClient(_ context.Context, name string, uris []string) (Client, error) {
	c := Client{ID: "aisvc_client_" + random(6), Name: name, RedirectURIs: uris, CreatedAt: time.Now()}
	m.clients[c.ID] = c
	return c, nil
}
func (m *mem) Client(_ context.Context, id string) (Client, error) {
	c, ok := m.clients[id]
	if !ok {
		return Client{}, ErrNotFound
	}
	return c, nil
}
func (m *mem) SaveCode(_ context.Context, c Code) error { m.codes[c.Hash] = c; return nil }
func (m *mem) TakeCode(_ context.Context, h string) (Code, error) {
	c, ok := m.codes[h]
	delete(m.codes, h)
	if !ok || time.Now().After(c.ExpiresAt) {
		return Code{}, ErrNotFound
	}
	return c, nil
}
func (m *mem) CreateGrant(_ context.Context, g Grant, _, refresh string, _ time.Duration) (Grant, string, error) {
	g.ID = int64(len(m.grants) + 1)
	m.grants[g.ID] = &memGrant{Grant: g, refresh: refresh}
	m.issued = append(m.issued, g)
	return g, "aisvc_mcp_" + random(32), nil
}
func (m *mem) Refresh(_ context.Context, old, nw, client string, exp time.Time, _ time.Duration) (Grant, string, error) {
	for _, g := range m.grants {
		if g.ClientID != client || !g.RevokedAt.IsZero() {
			continue
		}
		if g.refresh == old {
			g.prev, g.refresh, g.RefreshExpiresAt = old, nw, exp
			m.issued = append(m.issued, g.Grant)
			return g.Grant, "aisvc_mcp_" + random(32), nil
		}
		if g.prev == old {
			g.RevokedAt = time.Now()
			return Grant{}, "", ErrRefreshReuse
		}
	}
	return Grant{}, "", ErrNotFound
}
func (m *mem) RevokeGrantID(_ context.Context, id int64) error {
	if g := m.grants[id]; g != nil {
		g.RevokedAt = time.Now()
	}
	return nil
}
func (m *mem) RevokeByRefresh(_ context.Context, h, client string) error {
	for _, g := range m.grants {
		if g.refresh == h && g.ClientID == client {
			g.RevokedAt = time.Now()
		}
	}
	return nil
}
func (m *mem) Grants(context.Context, int64) ([]Grant, error)  { return nil, nil }
func (m *mem) RevokeGrant(context.Context, int64, int64) error { return nil }
func (m *mem) Memberships(_ context.Context, email string) ([]Member, error) {
	var out []Member
	for _, t := range m.team {
		if t.Email == email {
			out = append(out, t)
		}
	}
	return out, nil
}
func (m *mem) Team(context.Context, int64) ([]Member, error)     { return m.team, nil }
func (m *mem) AddMember(_ context.Context, mm Member) error      { m.team = append(m.team, mm); return nil }
func (m *mem) RemoveMember(context.Context, string, int64) error { return nil }

// --- harness ---

const (
	resource = "https://mcp.example.com/mcp"
	password = "correct horse battery"
	redirect = "https://claude.ai/api/mcp/auth_callback"
	verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk_extra_entropy"
)

func challenge(v string) string {
	s := sha256.Sum256([]byte(v))
	return base64.RawURLEncoding.EncodeToString(s[:])
}

type env struct {
	mux   *http.ServeMux
	store *mem
	ip    int
	srv   *Server
}

func (e *env) srvLogin() *Server { return e.srv }

func ratelimitReset() ratelimit.Limiter { return ratelimit.Limiter{} }

func newEnv() *env {
	st := newMem()
	s := &Server{Resource: resource, Password: password, Store: st, Logger: slog.New(slog.NewJSONHandler(io.Discard, nil))}
	mux := http.NewServeMux()
	s.Routes(mux)
	return &env{mux: mux, store: st, srv: s}
}

func (e *env) do(r *http.Request) *httptest.ResponseRecorder {
	rec := httptest.NewRecorder()
	e.mux.ServeHTTP(rec, r)
	return rec
}

func (e *env) register(t *testing.T, uris ...string) string {
	t.Helper()
	body, _ := json.Marshal(map[string]any{"client_name": "Claude", "redirect_uris": uris})
	rec := e.do(httptest.NewRequest(http.MethodPost, "/oauth/register", strings.NewReader(string(body))))
	var out map[string]any
	_ = json.Unmarshal(rec.Body.Bytes(), &out)
	id, _ := out["client_id"].(string)
	return id
}

func authForm(client string, extra map[string]string) url.Values {
	f := url.Values{"client_id": {client}, "redirect_uri": {redirect}, "response_type": {"code"}, "state": {"xyz"},
		"code_challenge": {challenge(verifier)}, "code_challenge_method": {"S256"}, "scope": {"kb:read kb:write"},
		"resource": {resource}, "account": {"1"}, "access": {"write"}, "password": {password}, "decision": {"approve"}}
	for k, v := range extra {
		f.Set(k, v)
	}
	return f
}

func (e *env) approve(f url.Values) *httptest.ResponseRecorder {
	e.ip++
	r := httptest.NewRequest(http.MethodPost, "/oauth/authorize", strings.NewReader(f.Encode()))
	r.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	r.Header.Set("Sec-Fetch-Site", "same-origin")
	r.RemoteAddr = "10.0.0." + string(rune('0'+e.ip%10)) + ":1"
	return e.do(r)
}

func (e *env) tokenReq(f url.Values) (*httptest.ResponseRecorder, map[string]any) {
	r := httptest.NewRequest(http.MethodPost, "/oauth/token", strings.NewReader(f.Encode()))
	r.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	rec := e.do(r)
	var out map[string]any
	_ = json.Unmarshal(rec.Body.Bytes(), &out)
	return rec, out
}

func codeFrom(t *testing.T, rec *httptest.ResponseRecorder) string {
	t.Helper()
	u, err := url.Parse(rec.Header().Get("Location"))
	if err != nil || rec.Code != http.StatusSeeOther {
		t.Fatalf("approve: code=%d loc=%q body=%s", rec.Code, rec.Header().Get("Location"), rec.Body)
	}
	if u.Query().Get("state") != "xyz" || u.Query().Get("iss") != "https://mcp.example.com" || !strings.HasPrefix(u.String(), redirect) {
		t.Fatalf("redirect = %s", u)
	}
	return u.Query().Get("code")
}

// --- tests ---

func TestDiscoveryDocuments(t *testing.T) {
	// Arrange
	e := newEnv()

	// Act
	prm := e.do(httptest.NewRequest(http.MethodGet, "/.well-known/oauth-protected-resource", nil))
	asm := e.do(httptest.NewRequest(http.MethodGet, "/.well-known/oauth-authorization-server", nil))

	// Assert
	var p, a map[string]any
	_ = json.Unmarshal(prm.Body.Bytes(), &p)
	_ = json.Unmarshal(asm.Body.Bytes(), &a)
	if p["resource"] != resource || p["authorization_servers"].([]any)[0] != "https://mcp.example.com" {
		t.Fatalf("protected resource metadata = %v", p)
	}
	if a["issuer"] != "https://mcp.example.com" || a["registration_endpoint"] != "https://mcp.example.com/oauth/register" ||
		a["code_challenge_methods_supported"].([]any)[0] != "S256" {
		t.Fatalf("server metadata = %v", a)
	}
}

func TestFullFlowThenRefreshRotationAndReuse(t *testing.T) {
	// Arrange
	e := newEnv()
	client := e.register(t, redirect)

	// Act
	page := e.do(httptest.NewRequest(http.MethodGet, "/oauth/authorize?"+authForm(client, nil).Encode(), nil))
	code := codeFrom(t, e.approve(authForm(client, nil)))
	rec, tok := e.tokenReq(url.Values{"grant_type": {"authorization_code"}, "code": {code}, "client_id": {client},
		"redirect_uri": {redirect}, "code_verifier": {verifier}, "resource": {resource}})
	replay, _ := e.tokenReq(url.Values{"grant_type": {"authorization_code"}, "code": {code}, "client_id": {client},
		"redirect_uri": {redirect}, "code_verifier": {verifier}})
	first := tok["refresh_token"].(string)
	_, refreshed := e.tokenReq(url.Values{"grant_type": {"refresh_token"}, "refresh_token": {first}, "client_id": {client}})
	reuse, _ := e.tokenReq(url.Values{"grant_type": {"refresh_token"}, "refresh_token": {first}, "client_id": {client}})
	afterReuse, _ := e.tokenReq(url.Values{"grant_type": {"refresh_token"}, "refresh_token": {refreshed["refresh_token"].(string)}, "client_id": {client}})

	// Assert
	if page.Code != http.StatusOK || !strings.Contains(page.Body.String(), "claude.ai") || !strings.Contains(page.Body.String(), "Claude") {
		t.Fatalf("consent page: %d", page.Code)
	}
	if page.Header().Get("X-Content-Type-Options") != "nosniff" {
		t.Error("consent page missing nosniff")
	}
	if !strings.Contains(page.Header().Get("Content-Security-Policy"), "frame-ancestors 'none'") {
		t.Error("consent page can be framed")
	}
	if rec.Code != http.StatusOK || !strings.HasPrefix(tok["access_token"].(string), "aisvc_mcp_") || tok["scope"] != "kb:read kb:write" {
		t.Fatalf("token: %d %v", rec.Code, tok)
	}
	if e.store.issued[0].AccountID != 1 || !e.store.issued[0].CanWrite {
		t.Fatalf("grant = %+v", e.store.issued[0])
	}
	if replay.Code != http.StatusBadRequest {
		t.Error("an authorization code worked twice")
	}
	if refreshed["refresh_token"] == first || refreshed["access_token"] == nil {
		t.Fatalf("refresh did not rotate: %v", refreshed)
	}
	if reuse.Code != http.StatusBadRequest || afterReuse.Code != http.StatusBadRequest {
		t.Fatalf("reused refresh token must revoke the connection: reuse=%d after=%d", reuse.Code, afterReuse.Code)
	}
}

func TestApproveRefusals(t *testing.T) {
	cases := map[string]struct {
		extra map[string]string
		want  int
	}{
		"wrong password":        {map[string]string{"password": "nope"}, http.StatusUnauthorized},
		"no pkce":               {map[string]string{"code_challenge_method": "plain"}, http.StatusBadRequest},
		"other redirect":        {map[string]string{"redirect_uri": "https://evil.example/cb"}, http.StatusBadRequest},
		"other resource":        {map[string]string{"resource": "https://other.example/mcp"}, http.StatusBadRequest},
		"unknown client":        {map[string]string{"client_id": "aisvc_client_nope"}, http.StatusBadRequest},
		"bad account":           {map[string]string{"account": "0"}, http.StatusUnprocessableEntity},
		"implicit flow refused": {map[string]string{"response_type": "token"}, http.StatusBadRequest},
	}
	for name, c := range cases {
		t.Run(name, func(t *testing.T) {
			// Arrange
			e := newEnv()
			client := e.register(t, redirect)

			// Act
			rec := e.approve(authForm(client, c.extra))

			// Assert
			if rec.Code != c.want || rec.Header().Get("Location") != "" || len(e.store.codes) != 0 {
				t.Fatalf("code=%d loc=%q codes=%d", rec.Code, rec.Header().Get("Location"), len(e.store.codes))
			}
		})
	}
}

func TestDenyRedirectsWithAccessDenied(t *testing.T) {
	// Arrange
	e := newEnv()
	client := e.register(t, redirect)

	// Act
	rec := e.approve(authForm(client, map[string]string{"decision": "deny", "password": ""}))

	// Assert
	u, _ := url.Parse(rec.Header().Get("Location"))
	if rec.Code != http.StatusSeeOther || u.Query().Get("error") != "access_denied" || u.Query().Get("code") != "" {
		t.Fatalf("code=%d loc=%s", rec.Code, u)
	}
}

func TestTokenRefusals(t *testing.T) {
	// Arrange
	e := newEnv()
	client := e.register(t, redirect)
	other := e.register(t, redirect)
	fresh := func() string { return codeFrom(t, e.approve(authForm(client, nil))) }

	cases := map[string]url.Values{
		"wrong verifier": {"code_verifier": {verifier + "x"}},
		"other client":   {"client_id": {other}},
		"other redirect": {"redirect_uri": {"https://claude.ai/other"}},
		"other resource": {"resource": {"https://other.example/mcp"}},
	}
	for name, override := range cases {
		t.Run(name, func(t *testing.T) {
			f := url.Values{"grant_type": {"authorization_code"}, "code": {fresh()}, "client_id": {client},
				"redirect_uri": {redirect}, "code_verifier": {verifier}}
			for k, v := range override {
				f[k] = v
			}

			// Act
			rec, _ := e.tokenReq(f)

			// Assert
			if rec.Code != http.StatusBadRequest {
				t.Fatalf("code = %d", rec.Code)
			}
		})
	}
	if len(e.store.issued) != 0 {
		t.Fatalf("tokens issued on refused requests: %d", len(e.store.issued))
	}
}

func TestRegisterRejectsUnsafeRedirects(t *testing.T) {
	for _, uri := range []string{"http://evil.example/cb", "javascript:alert(1)", "https://claude.ai/cb#frag", "https://user:pw@claude.ai/cb", "myapp://cb"} {
		// Arrange
		e := newEnv()

		// Act
		id := e.register(t, uri)

		// Assert
		if id != "" {
			t.Errorf("registered %q", uri)
		}
	}
	// Desktop apps on this machine are fine.
	if newEnv().register(t, "http://127.0.0.1:33418/callback") == "" {
		t.Error("localhost redirect refused")
	}
}

func TestPasswordAttemptsLimited(t *testing.T) {
	// Arrange
	e := newEnv()
	client := e.register(t, redirect)
	f := authForm(client, map[string]string{"password": "guess"})

	// Act
	var last int
	for i := 0; i < 6; i++ {
		r := httptest.NewRequest(http.MethodPost, "/oauth/authorize", strings.NewReader(f.Encode()))
		r.Header.Set("Content-Type", "application/x-www-form-urlencoded")
		r.RemoteAddr = "10.9.9.9:1"
		last = e.do(r).Code
	}

	// Assert
	if last != http.StatusTooManyRequests {
		t.Fatalf("6th attempt = %d, want 429", last)
	}
}

func TestApproveRefusesCrossSitePost(t *testing.T) {
	// Arrange
	e := newEnv()
	client := e.register(t, redirect)
	r := httptest.NewRequest(http.MethodPost, "/oauth/authorize", strings.NewReader(authForm(client, nil).Encode()))
	r.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	r.Header.Set("Sec-Fetch-Site", "cross-site")

	// Act
	rec := e.do(r)

	// Assert
	if rec.Code != http.StatusForbidden || len(e.store.codes) != 0 {
		t.Fatalf("code=%d", rec.Code)
	}
}

func TestWrongPasswordRetryKeepsRedirectAllowed(t *testing.T) {
	// Arrange
	e := newEnv()
	client := e.register(t, redirect)

	// Act
	rec := e.approve(authForm(client, map[string]string{"password": "nope"}))

	// Assert: the re-shown form must still be able to redirect to the app.
	if rec.Code != http.StatusUnauthorized || !strings.Contains(rec.Header().Get("Content-Security-Policy"), "form-action 'self' https://claude.ai") {
		t.Fatalf("code=%d csp=%q", rec.Code, rec.Header().Get("Content-Security-Policy"))
	}
}

func TestUnknownAppGetsWarning(t *testing.T) {
	// Arrange
	e := newEnv()
	known := e.register(t, redirect)
	unknown := e.register(t, "https://evil.example/cb")
	q := func(c, ru string) string {
		f := authForm(c, map[string]string{"redirect_uri": ru})
		return "/oauth/authorize?" + f.Encode()
	}

	// Act
	k := e.do(httptest.NewRequest(http.MethodGet, q(known, redirect), nil)).Body.String()
	u := e.do(httptest.NewRequest(http.MethodGet, q(unknown, "https://evil.example/cb"), nil)).Body.String()

	// Assert
	if strings.Contains(k, "Unknown app") || !strings.Contains(u, "Unknown app") || !strings.Contains(u, "evil.example") {
		t.Fatal("unknown-app warning wrong")
	}
}

func TestDailyFailedPasswordLockIsPerAddress(t *testing.T) {
	// Arrange: one address guesses 30 times (spread over minutes in reality).
	e := newEnv()
	client := e.register(t, redirect)
	post := func(f url.Values, ip string) int {
		r := httptest.NewRequest(http.MethodPost, "/oauth/authorize", strings.NewReader(f.Encode()))
		r.Header.Set("Content-Type", "application/x-www-form-urlencoded")
		r.RemoteAddr = "172.18.0.5:1" // the tunnel
		r.Header.Set("CF-Connecting-IP", ip)
		return e.do(r).Code
	}
	for i := 0; i < maxFailedPerDay; i++ {
		e.srvLogin().login = ratelimitReset() // only the daily counter matters here
		post(authForm(client, map[string]string{"password": "guess"}), "203.0.113.66")
	}

	// Act
	attacker := post(authForm(client, nil), "203.0.113.66")
	owner := post(authForm(client, nil), "198.51.100.1")

	// Assert: the guessing address is locked even with the right password; the owner is not.
	if attacker != http.StatusTooManyRequests || owner != http.StatusSeeOther {
		t.Fatalf("attacker=%d owner=%d", attacker, owner)
	}
}

func TestClientNameStripsControlCharacters(t *testing.T) {
	// Arrange
	e := newEnv()
	body := `{"client_name":"Cla\u202eude\u0007","redirect_uris":["` + redirect + `"]}`

	// Act
	e.do(httptest.NewRequest(http.MethodPost, "/oauth/register", strings.NewReader(body)))

	// Assert
	for _, c := range e.store.clients {
		if c.Name != "Claude" {
			t.Fatalf("name = %q", c.Name)
		}
	}
}

func TestGlobalDailyFailureCap(t *testing.T) {
	// Arrange: wrong passwords from many addresses, each under its own limit.
	e := newEnv()
	client := e.register(t, redirect)
	post := func(f url.Values, ip string) int {
		e.srv.login = ratelimit.Limiter{} // isolate the daily counters
		r := httptest.NewRequest(http.MethodPost, "/oauth/authorize", strings.NewReader(f.Encode()))
		r.Header.Set("Content-Type", "application/x-www-form-urlencoded")
		r.RemoteAddr = "172.18.0.5:1"
		r.Header.Set("CF-Connecting-IP", ip)
		return e.do(r).Code
	}
	for i := 0; i < maxFailedAllPerDay; i++ {
		post(authForm(client, map[string]string{"password": "guess"}), "203.0."+strconv.Itoa(i/250)+"."+strconv.Itoa(i%250+1))
	}

	// Act
	fresh := post(authForm(client, nil), "198.51.100.1")

	// Assert
	if fresh != http.StatusTooManyRequests {
		t.Fatalf("after %d failures from many addresses, approval = %d, want 429", maxFailedAllPerDay, fresh)
	}
}

// --- Cloudflare Access mode ---

type fakeAccess struct{ byToken map[string]string }

func (f fakeAccess) Verify(_ context.Context, tok string) (cfaccess.Identity, error) {
	if email, ok := f.byToken[tok]; ok {
		return cfaccess.Identity{Email: email}, nil
	}
	return cfaccess.Identity{}, cfaccess.ErrInvalid
}

func accessEnv() *env {
	e := newEnv()
	e.srv.Access = fakeAccess{byToken: map[string]string{"jwt-somchai": "somchai@example.com", "jwt-stranger": "stranger@example.com"}}
	e.store.team = []Member{{Email: "somchai@example.com", AccountID: 1, CanWrite: true}, {Email: "somchai@example.com", AccountID: 2}}
	return e
}

func (e *env) approveAs(jwt string, f url.Values) *httptest.ResponseRecorder {
	r := httptest.NewRequest(http.MethodPost, "/oauth/authorize", strings.NewReader(f.Encode()))
	r.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	if jwt != "" {
		r.Header.Set(cfaccess.Header, jwt)
	}
	return e.do(r)
}

func TestAccess_MemberApprovesWithoutPassword(t *testing.T) {
	// Arrange
	e := accessEnv()
	client := e.register(t, redirect)
	page := httptest.NewRequest(http.MethodGet, "/oauth/authorize?"+authForm(client, nil).Encode(), nil)
	page.Header.Set(cfaccess.Header, "jwt-somchai")

	// Act
	shown := e.do(page).Body.String()
	rec := e.approveAs("jwt-somchai", authForm(client, map[string]string{"password": ""}))
	code := codeFrom(t, rec)
	_, tok := e.tokenReq(url.Values{"grant_type": {"authorization_code"}, "code": {code}, "client_id": {client},
		"redirect_uri": {redirect}, "code_verifier": {verifier}})

	// Assert
	if !strings.Contains(shown, "somchai@example.com") || strings.Contains(shown, `type="password"`) || !strings.Contains(shown, "Account 2 (read only)") {
		t.Fatal("consent page should show the signed-in member, their accounts, and no password field")
	}
	if tok["access_token"] == nil || e.store.issued[0].ApprovedBy != "somchai@example.com" || e.store.issued[0].AccountID != 1 {
		t.Fatalf("grant = %+v", e.store.issued)
	}
}

func TestAccess_Refusals(t *testing.T) {
	cases := map[string]struct {
		jwt   string
		extra map[string]string
		want  int
	}{
		"no access token":       {"", nil, http.StatusForbidden},
		"forged access token":   {"jwt-forged", nil, http.StatusForbidden},
		"not on the team":       {"jwt-stranger", nil, http.StatusForbidden},
		"other account":         {"jwt-somchai", map[string]string{"account": "3"}, http.StatusUnprocessableEntity},
		"write on read account": {"jwt-somchai", map[string]string{"account": "2", "access": "write"}, http.StatusForbidden},
		"unknown return host":   {"jwt-somchai", map[string]string{"redirect_uri": "https://evil.example/cb"}, http.StatusForbidden},
	}
	for name, c := range cases {
		t.Run(name, func(t *testing.T) {
			// Arrange
			e := accessEnv()
			client := e.register(t, redirect, "https://evil.example/cb")

			// Act
			rec := e.approveAs(c.jwt, authForm(client, c.extra))

			// Assert
			if rec.Code != c.want || rec.Header().Get("Location") != "" || len(e.store.codes) != 0 {
				t.Fatalf("code=%d loc=%q", rec.Code, rec.Header().Get("Location"))
			}
		})
	}
}

func TestAccess_ReadOnlyMemberGetsReadToken(t *testing.T) {
	// Arrange
	e := accessEnv()
	client := e.register(t, redirect)

	// Act
	code := codeFrom(t, e.approveAs("jwt-somchai", authForm(client, map[string]string{"account": "2", "access": "read"})))
	_, tok := e.tokenReq(url.Values{"grant_type": {"authorization_code"}, "code": {code}, "client_id": {client},
		"redirect_uri": {redirect}, "code_verifier": {verifier}})

	// Assert
	if tok["scope"] != "kb:read" || e.store.issued[0].CanWrite {
		t.Fatalf("scope=%v grant=%+v", tok["scope"], e.store.issued[0])
	}
}

func TestAccess_OwnerApprovesAnyAccountWithWrite(t *testing.T) {
	// Arrange: the owner is not on any team list.
	e := accessEnv()
	e.srv.Owners = []string{"john@example.com"}
	e.srv.Access = fakeAccess{byToken: map[string]string{"jwt-john": "john@example.com"}}
	client := e.register(t, redirect)

	// Act
	code := codeFrom(t, e.approveAs("jwt-john", authForm(client, map[string]string{"account": "7", "password": ""})))
	_, tok := e.tokenReq(url.Values{"grant_type": {"authorization_code"}, "code": {code}, "client_id": {client},
		"redirect_uri": {redirect}, "code_verifier": {verifier}})

	// Assert
	g := e.store.issued[0]
	if tok["scope"] != "kb:read kb:write" || g.AccountID != 7 || g.ApprovedBy != "john@example.com" || !g.ByOwner {
		t.Fatalf("scope=%v grant=%+v", tok["scope"], g)
	}
}

func TestAccess_OwnerRemovedFromListLosesConnectionOnRefresh(t *testing.T) {
	// Arrange: an owner connects an app, then is taken off ADMIN_EMAILS.
	e := accessEnv()
	e.srv.Owners = []string{"john@example.com"}
	e.srv.Access = fakeAccess{byToken: map[string]string{"jwt-john": "john@example.com"}}
	client := e.register(t, redirect)
	code := codeFrom(t, e.approveAs("jwt-john", authForm(client, map[string]string{"account": "7", "password": ""})))
	_, tok := e.tokenReq(url.Values{"grant_type": {"authorization_code"}, "code": {code}, "client_id": {client},
		"redirect_uri": {redirect}, "code_verifier": {verifier}})
	e.srv.Owners = nil

	// Act
	rec, out := e.tokenReq(url.Values{"grant_type": {"refresh_token"}, "refresh_token": {tok["refresh_token"].(string)}, "client_id": {client}})

	// Assert
	if rec.Code != http.StatusBadRequest || out["access_token"] != nil {
		t.Fatalf("refresh after removal: code=%d out=%v", rec.Code, out)
	}
	for _, g := range e.store.grants {
		if g.RevokedAt.IsZero() {
			t.Fatal("the connection was not revoked")
		}
	}
}

func TestConsentPage_ProntoBrand(t *testing.T) {
	// Arrange
	e := newEnv()
	client := e.register(t, redirect)

	// Act
	page := e.do(httptest.NewRequest(http.MethodGet, "/oauth/authorize?"+authForm(client, nil).Encode(), nil))
	body := page.Body.String()
	csp := page.Header().Get("Content-Security-Policy")

	// Assert
	if !strings.Contains(body, `aria-label="Pronto"`) || !strings.Contains(body, "<title>Connect an AI app · Pronto</title>") {
		t.Error("consent page not branded Pronto")
	}
	if !strings.Contains(html.UnescapeString(body), `<link rel="icon" type="image/svg+xml" href="data:image/svg+xml;base64,`) {
		t.Error("consent page has no Pronto favicon")
	}
	if !strings.Contains(csp, "img-src data:;") || strings.Contains(csp, "img-src *") || !strings.Contains(csp, "default-src 'none'") {
		t.Errorf("consent CSP = %s", csp)
	}
	if strings.Contains(strings.ToLower(body), "#1f6feb") {
		t.Error("old blue accent still on consent page")
	}
}
