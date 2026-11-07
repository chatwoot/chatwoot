package oauth

import (
	"context"
	"crypto/sha256"
	"crypto/subtle"
	"embed"
	"encoding/base64"
	"encoding/json"
	"errors"
	"html/template"
	"log/slog"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"
	"unicode"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/cfaccess"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/mcp"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/ratelimit"
)

// Identifier verifies the Cloudflare Access token (cfaccess.Verifier).
type Identifier interface {
	Verify(ctx context.Context, token string) (cfaccess.Identity, error)
}

// Scopes.
const (
	ScopeRead  = "kb:read"
	ScopeWrite = "kb:write"
)

// maxFailedPerDay locks approvals from one address for the rest of the day
// after this many wrong passwords (others, and /admin, are unaffected).
const maxFailedPerDay = 30

// maxFailedAllPerDay caps wrong passwords from all addresses together, so
// guessing spread over many addresses is still bounded. Reaching it locks
// approvals for everyone until the day window ends; /admin is unaffected.
const maxFailedAllPerDay = 200

// Lifetimes.
const (
	codeTTL    = time.Minute
	accessTTL  = time.Hour
	refreshTTL = 90 * 24 * time.Hour
)

//go:embed consent.html
var pageFS embed.FS

var consent = template.Must(template.ParseFS(pageFS, "consent.html"))

// Server is the authorization server plus the discovery documents.
type Server struct {
	// Resource is the MCP endpoint URL, e.g. https://ai-mcp.example.com/mcp.
	// The issuer is its origin.
	Resource string
	Password string // the admin password approves each app (without Access)
	Store    Store
	// Access, when set, identifies the person through Cloudflare Access
	// instead of the admin password; only team members can approve, and
	// only for their accounts and access.
	Access Identifier
	// Owners (ADMIN_EMAILS) may approve for any account with write access.
	Owners []string
	Logger *slog.Logger

	// login counts password attempts only, so other endpoints cannot fill
	// its table; other counts registrations and token calls. failedDay caps
	// wrong passwords per day across all callers.
	login, other ratelimit.Limiter
	failedDay    ratelimit.Limiter // per address; Period set in Routes
	failedAll    ratelimit.Limiter // one key for all addresses, so a full failedDay table cannot hide failures
}

// trustedHosts are the return addresses of well-known AI apps. Others get a
// stronger warning on the consent page.
var trustedHosts = map[string]bool{"claude.ai": true, "claude.com": true, "chatgpt.com": true, "chat.openai.com": true}

// Issuer is the authorization server's identifier: the resource's origin.
func (s *Server) Issuer() string {
	u, err := url.Parse(s.Resource)
	if err != nil {
		return ""
	}
	return u.Scheme + "://" + u.Host
}

// MetadataURL is where the MCP server's protected resource metadata lives.
func (s *Server) MetadataURL() string {
	return s.Issuer() + "/.well-known/oauth-protected-resource"
}

// Routes registers the OAuth endpoints on mux.
func (s *Server) Routes(mux *http.ServeMux) {
	s.failedDay.Period = 24 * time.Hour
	s.failedAll.Period = 24 * time.Hour
	mux.HandleFunc("GET /.well-known/oauth-protected-resource", s.resourceMetadata)
	if u, err := url.Parse(s.Resource); err == nil && u.Path != "" && u.Path != "/" {
		mux.HandleFunc("GET /.well-known/oauth-protected-resource"+u.Path, s.resourceMetadata)
	}
	mux.HandleFunc("GET /.well-known/oauth-authorization-server", s.serverMetadata)
	mux.HandleFunc("POST /oauth/register", s.register)
	mux.HandleFunc("GET /oauth/authorize", s.authorizePage)
	mux.Handle("POST /oauth/authorize", http.NewCrossOriginProtection().Handler(http.HandlerFunc(s.approve)))
	mux.HandleFunc("POST /oauth/token", s.token)
	mux.HandleFunc("POST /oauth/revoke", s.revoke)
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "no-store")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

func oauthError(w http.ResponseWriter, status int, code, desc string) {
	writeJSON(w, status, map[string]string{"error": code, "error_description": desc})
}

func (s *Server) resourceMetadata(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{
		"resource":                 s.Resource,
		"authorization_servers":    []string{s.Issuer()},
		"scopes_supported":         []string{ScopeRead, ScopeWrite},
		"bearer_methods_supported": []string{"header"},
		"resource_name":            "ai-service knowledge base",
	})
}

func (s *Server) serverMetadata(w http.ResponseWriter, _ *http.Request) {
	iss := s.Issuer()
	writeJSON(w, http.StatusOK, map[string]any{
		"issuer":                                         iss,
		"authorization_endpoint":                         iss + "/oauth/authorize",
		"token_endpoint":                                 iss + "/oauth/token",
		"registration_endpoint":                          iss + "/oauth/register",
		"revocation_endpoint":                            iss + "/oauth/revoke",
		"response_types_supported":                       []string{"code"},
		"grant_types_supported":                          []string{"authorization_code", "refresh_token"},
		"code_challenge_methods_supported":               []string{"S256"},
		"token_endpoint_auth_methods_supported":          []string{"none"},
		"revocation_endpoint_auth_methods_supported":     []string{"none"},
		"scopes_supported":                               []string{ScopeRead, ScopeWrite},
		"authorization_response_iss_parameter_supported": true,
	})
}

// validRedirect accepts https URLs, and http only for the local machine
// (desktop apps), with no fragment and no user info.
func validRedirect(raw string) bool {
	u, err := url.Parse(raw)
	if err != nil || len(raw) > 2000 || u.Fragment != "" || u.User != nil || u.Host == "" {
		return false
	}
	switch u.Scheme {
	case "https":
		return true
	case "http":
		h := u.Hostname()
		return h == "localhost" || h == "127.0.0.1" || h == "::1"
	}
	return false
}

func (s *Server) register(w http.ResponseWriter, r *http.Request) {
	if !s.other.Allow("register:"+ratelimit.ClientIP(r), 10) || !s.other.Allow("register", 60) {
		oauthError(w, http.StatusTooManyRequests, "slow_down", "too many registrations; wait a minute")
		return
	}
	var req struct {
		ClientName   string   `json:"client_name"`
		RedirectURIs []string `json:"redirect_uris"`
	}
	if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 16<<10)).Decode(&req); err != nil {
		oauthError(w, http.StatusBadRequest, "invalid_client_metadata", "expected a JSON client registration")
		return
	}
	if len(req.RedirectURIs) == 0 || len(req.RedirectURIs) > 5 {
		oauthError(w, http.StatusBadRequest, "invalid_redirect_uri", "give 1 to 5 redirect_uris")
		return
	}
	for _, u := range req.RedirectURIs {
		if !validRedirect(u) {
			oauthError(w, http.StatusBadRequest, "invalid_redirect_uri", "redirect URIs must be https, or http on localhost")
			return
		}
	}
	name := strings.TrimSpace(strings.Map(func(r rune) rune {
		if unicode.IsControl(r) || unicode.Is(unicode.Cf, r) { // control and bidi/format characters
			return -1
		}
		return r
	}, req.ClientName))
	if r := []rune(name); len(r) > 80 {
		name = string(r[:80])
	}
	if name == "" {
		name = "Unnamed app"
	}
	c, err := s.Store.RegisterClient(r.Context(), name, req.RedirectURIs)
	if err != nil {
		s.Logger.Error("oauth register failed", "error", err)
		oauthError(w, http.StatusInternalServerError, "server_error", "try again later")
		return
	}
	s.Logger.Info("oauth client registered", "client_id", c.ID, "redirect_hosts", redirectHosts(c.RedirectURIs))
	writeJSON(w, http.StatusCreated, map[string]any{
		"client_id": c.ID, "client_name": c.Name, "redirect_uris": c.RedirectURIs,
		"client_id_issued_at":        c.CreatedAt.Unix(),
		"token_endpoint_auth_method": "none",
		"grant_types":                []string{"authorization_code", "refresh_token"},
		"response_types":             []string{"code"},
	})
}

func redirectHosts(uris []string) []string {
	var out []string
	for _, raw := range uris {
		if u, err := url.Parse(raw); err == nil {
			out = append(out, u.Host)
		}
	}
	return out
}

// authRequest is a validated /oauth/authorize request.
type authRequest struct {
	Client      Client
	RedirectURI string
	State       string
	Challenge   string
	Scope       string
	Resource    string
	WantsWrite  bool
}

// parseAuth validates the request. Errors before the redirect URI is trusted
// are shown on our page; never redirect to an unchecked URI.
func (s *Server) parseAuth(r *http.Request, q url.Values) (authRequest, string) {
	a := authRequest{RedirectURI: q.Get("redirect_uri"), State: q.Get("state"), Challenge: q.Get("code_challenge"),
		Scope: q.Get("scope"), Resource: strings.TrimSuffix(q.Get("resource"), "/")}
	c, err := s.Store.Client(r.Context(), q.Get("client_id"))
	if err != nil {
		return a, "This app is not registered. Start the connection again from the app."
	}
	a.Client = c
	ok := false
	for _, u := range c.RedirectURIs {
		if u == a.RedirectURI {
			ok = true
		}
	}
	if !ok {
		return a, "The app's return address does not match its registration."
	}
	switch {
	case q.Get("response_type") != "code":
		return a, "Only the authorization code flow is supported."
	case q.Get("code_challenge_method") != "S256" || len(a.Challenge) < 43 || len(a.Challenge) > 128:
		return a, "The app must use PKCE (S256)."
	case a.Resource != "" && a.Resource != strings.TrimSuffix(s.Resource, "/"):
		return a, "This sign-in is for a different server."
	}
	for _, sc := range strings.Fields(a.Scope) {
		if sc == ScopeWrite {
			a.WantsWrite = true
		}
	}
	return a, ""
}

type pageData struct {
	authRequest
	ClientID   string
	ReturnHost string
	Trusted    bool // the return host is a well-known AI app or this computer
	Valid      bool // the request itself checked out, so its redirect is trusted
	Error      string
	Account    string
	Write      bool
	Email      string   // signed in through Access
	Accounts   []Member // the person's accounts (Access mode)
	Owner      bool     // an owner: any account, write allowed
}

func (d *pageData) setReturn() {
	if u, err := url.Parse(d.RedirectURI); err == nil {
		d.ReturnHost = u.Host
		h := u.Hostname()
		d.Trusted = trustedHosts[h] || h == "localhost" || h == "127.0.0.1" || h == "::1"
	}
}

func (s *Server) render(w http.ResponseWriter, status int, d pageData) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Header().Set("Cache-Control", "no-store")
	w.Header().Set("X-Frame-Options", "DENY")
	w.Header().Set("Referrer-Policy", "no-referrer")
	formAction := "'self'"
	if u, err := url.Parse(d.RedirectURI); err == nil && d.Valid && u.Host != "" {
		formAction += " " + u.Scheme + "://" + u.Host // the approval redirects there
	}
	w.Header().Set("Content-Security-Policy", "default-src 'none'; style-src 'unsafe-inline'; form-action "+formAction+"; frame-ancestors 'none'; base-uri 'none'")
	w.Header().Set("X-Content-Type-Options", "nosniff")
	w.WriteHeader(status)
	if err := consent.Execute(w, d); err != nil {
		s.Logger.Error("render consent page", "error", err)
	}
}

// identify returns the Access-verified person and their accounts, or an
// error message for the page. Without Access it returns no email.
func (s *Server) identify(r *http.Request, d *pageData) bool {
	if s.Access == nil {
		return true
	}
	id, err := s.Access.Verify(r.Context(), r.Header.Get(cfaccess.Header))
	if err != nil {
		s.Logger.Warn("oauth approval without a valid Cloudflare Access sign-in", "client_ip", ratelimit.ClientIP(r))
		d.Error, d.Valid = "Sign in through Cloudflare Access first: open this page from the app again.", false
		return false
	}
	if s.isOwner(id.Email) {
		d.Email, d.Owner = id.Email, true
		if !d.Trusted {
			d.Error, d.Valid = d.ReturnHost+" is not Claude, ChatGPT or an app on this computer. Use an access token for other tools.", false
			return false
		}
		return true
	}
	members, err := s.Store.Memberships(r.Context(), id.Email)
	if err != nil {
		s.Logger.Error("oauth team lookup failed", "error", err)
		d.Error, d.Valid = "Something went wrong. Try again.", false
		return false
	}
	d.Email, d.Accounts = id.Email, members
	if !d.Trusted {
		// Team members can only connect Claude, ChatGPT or an app on their own
		// computer; other return addresses could be phishing.
		d.Error, d.Valid = d.ReturnHost+" is not Claude, ChatGPT or an app on this computer, so team members cannot approve it.", false
		return false
	}
	if len(members) == 0 {
		d.Error, d.Valid = id.Email+" is not on the team. Ask the owner to add you on the admin page (Connect AI tools).", false
		return false
	}
	if d.Account == "" && len(members) == 1 {
		d.Account = strconv.FormatInt(members[0].AccountID, 10)
	}
	return true
}

func (s *Server) authorizePage(w http.ResponseWriter, r *http.Request) {
	if !s.other.Allow("authorize:"+ratelimit.ClientIP(r), 60) {
		http.Error(w, "too many requests; wait a minute", http.StatusTooManyRequests)
		return
	}
	a, problem := s.parseAuth(r, r.URL.Query())
	d := pageData{authRequest: a, ClientID: a.Client.ID, Error: problem, Valid: problem == "", Write: a.WantsWrite}
	d.setReturn()
	status := http.StatusOK
	if problem != "" {
		status = http.StatusBadRequest
	} else if !s.identify(r, &d) {
		status = http.StatusForbidden
	}
	s.render(w, status, d)
}

func (s *Server) approve(w http.ResponseWriter, r *http.Request) {
	r.Body = http.MaxBytesReader(w, r.Body, 16<<10)
	if err := r.ParseForm(); err != nil {
		http.Error(w, "invalid form", http.StatusBadRequest)
		return
	}
	f := r.PostForm
	a, problem := s.parseAuth(r, f)
	d := pageData{authRequest: a, ClientID: a.Client.ID, Error: problem, Valid: problem == "", Account: f.Get("account"), Write: f.Get("access") == "write"}
	d.setReturn()
	if problem != "" {
		s.render(w, http.StatusBadRequest, d)
		return
	}
	redirect, _ := url.Parse(a.RedirectURI)
	q := redirect.Query()
	q.Set("iss", s.Issuer())
	if a.State != "" {
		q.Set("state", a.State)
	}
	if f.Get("decision") == "deny" {
		q.Set("error", "access_denied")
		redirect.RawQuery = q.Encode()
		http.Redirect(w, r, redirect.String(), http.StatusSeeOther)
		return
	}
	var approver string
	var acct int64
	if s.Access != nil {
		if !s.login.Allow("login:"+ratelimit.ClientIP(r), 20) {
			d.Error = "Too many attempts. Wait a minute and try again."
			s.render(w, http.StatusTooManyRequests, d)
			return
		}
		if !s.identify(r, &d) {
			s.render(w, http.StatusForbidden, d)
			return
		}
		m, ok := memberFor(d.Accounts, d.Account)
		if d.Owner {
			n, err := strconv.ParseInt(strings.TrimSpace(d.Account), 10, 64)
			m, ok = Member{Email: d.Email, AccountID: n, CanWrite: true}, err == nil && n > 0
		}
		if !ok {
			d.Error = "Choose one of your accounts."
			s.render(w, http.StatusUnprocessableEntity, d)
			return
		}
		if d.Write && !m.CanWrite {
			d.Error = "You have read-only access to this account. Choose Read only, or ask the owner for write access."
			s.render(w, http.StatusForbidden, d)
			return
		}
		approver, acct = d.Email, m.AccountID
	} else {
		if !s.login.Allow("login:"+ratelimit.ClientIP(r), 5) || !s.login.Allow("login", 20) ||
			s.failedDay.Reached("failed:"+ratelimit.ClientIP(r), maxFailedPerDay) || s.failedAll.Reached("all", maxFailedAllPerDay) {
			d.Error = "Too many attempts. Wait a minute and try again."
			s.render(w, http.StatusTooManyRequests, d)
			return
		}
		want := sha256.Sum256([]byte(s.Password))
		got := sha256.Sum256([]byte(f.Get("password")))
		if s.Password == "" || subtle.ConstantTimeCompare(want[:], got[:]) != 1 {
			s.Logger.Warn("oauth approval: wrong password", "client_id", a.Client.ID, "client_ip", ratelimit.ClientIP(r))
			if !s.failedDay.Allow("failed:"+ratelimit.ClientIP(r), maxFailedPerDay) {
				s.Logger.Error("oauth approvals locked for one address: too many wrong passwords today", "client_ip", ratelimit.ClientIP(r))
			}
			if !s.failedAll.Allow("all", maxFailedAllPerDay) {
				s.Logger.Error("oauth approvals locked for everyone today: too many wrong passwords from many addresses")
			}
			d.Error = "Wrong password."
			s.render(w, http.StatusUnauthorized, d)
			return
		}
		n, err := strconv.ParseInt(strings.TrimSpace(d.Account), 10, 64)
		if err != nil || n < 1 {
			d.Error = "Account must be a positive number."
			s.render(w, http.StatusUnprocessableEntity, d)
			return
		}
		acct = n
	}
	code := random(32)
	if err := s.Store.SaveCode(r.Context(), Code{Hash: mcp.HashToken(code), ClientID: a.Client.ID, RedirectURI: a.RedirectURI,
		Challenge: a.Challenge, Resource: s.Resource, AccountID: acct, CanWrite: d.Write, ExpiresAt: time.Now().Add(codeTTL), ApprovedBy: approver}); err != nil {
		s.Logger.Error("oauth save code failed", "error", err)
		d.Error = "Something went wrong. Try again."
		s.render(w, http.StatusInternalServerError, d)
		return
	}
	s.Logger.Info("oauth app approved", "client_id", a.Client.ID, "account_id", acct, "can_write", d.Write, "by_team_member", approver != "", "client_ip", ratelimit.ClientIP(r))
	q.Set("code", code)
	redirect.RawQuery = q.Encode()
	http.Redirect(w, r, redirect.String(), http.StatusSeeOther)
}

// approverStillAllowed re-checks, on every refresh, that whoever approved a
// connection still may: an owner still listed, or a team member still on the
// account (with write if the connection writes). Password approvals (no
// approver) are unaffected.
func (s *Server) approverStillAllowed(ctx context.Context, g Grant) bool {
	if g.ApprovedBy == "" || s.isOwner(g.ApprovedBy) {
		return true
	}
	ms, err := s.Store.Memberships(ctx, g.ApprovedBy)
	if err != nil {
		return true // a lookup error must not log everyone out; removal revokes anyway
	}
	for _, m := range ms {
		if m.AccountID == g.AccountID && (m.CanWrite || !g.CanWrite) {
			return true
		}
	}
	return false
}

func (s *Server) isOwner(email string) bool {
	for _, o := range s.Owners {
		if email != "" && o == email {
			return true
		}
	}
	return false
}

func memberFor(ms []Member, account string) (Member, bool) {
	n, err := strconv.ParseInt(strings.TrimSpace(account), 10, 64)
	if err != nil {
		return Member{}, false
	}
	for _, m := range ms {
		if m.AccountID == n {
			return m, true
		}
	}
	return Member{}, false
}

func pkceOK(verifier, challenge string) bool {
	if len(verifier) < 43 || len(verifier) > 128 {
		return false
	}
	sum := sha256.Sum256([]byte(verifier))
	return subtle.ConstantTimeCompare([]byte(base64.RawURLEncoding.EncodeToString(sum[:])), []byte(challenge)) == 1
}

func (s *Server) token(w http.ResponseWriter, r *http.Request) {
	if !s.other.Allow("token:"+ratelimit.ClientIP(r), 60) {
		oauthError(w, http.StatusTooManyRequests, "slow_down", "wait a minute")
		return
	}
	r.Body = http.MaxBytesReader(w, r.Body, 16<<10)
	if err := r.ParseForm(); err != nil {
		oauthError(w, http.StatusBadRequest, "invalid_request", "expected a form body")
		return
	}
	f := r.PostForm
	clientID := f.Get("client_id")
	if res := strings.TrimSuffix(f.Get("resource"), "/"); res != "" && res != strings.TrimSuffix(s.Resource, "/") {
		oauthError(w, http.StatusBadRequest, "invalid_target", "tokens here are only for "+s.Resource)
		return
	}
	var g Grant
	var refresh, access string
	switch f.Get("grant_type") {
	case "authorization_code":
		codeHash := mcp.HashToken(f.Get("code"))
		c, err := s.Store.TakeCode(r.Context(), codeHash)
		if errors.Is(err, ErrCodeReuse) {
			s.Logger.Warn("oauth code reused; its connection was revoked", "client_id", clientID)
		}
		if err != nil || c.ClientID != clientID || c.RedirectURI != f.Get("redirect_uri") || !pkceOK(f.Get("code_verifier"), c.Challenge) {
			oauthError(w, http.StatusBadRequest, "invalid_grant", "the code is invalid, expired, used, or does not match")
			return
		}
		client, err := s.Store.Client(r.Context(), clientID)
		if err != nil {
			oauthError(w, http.StatusBadRequest, "invalid_client", "unknown client")
			return
		}
		refresh = random(32)
		g = Grant{AccountID: c.AccountID, ClientID: clientID, ClientName: client.Name, CanWrite: c.CanWrite,
			RefreshExpiresAt: time.Now().Add(refreshTTL), ApprovedBy: c.ApprovedBy, ByOwner: s.isOwner(c.ApprovedBy)}
		if g, access, err = s.Store.CreateGrant(r.Context(), g, codeHash, mcp.HashToken(refresh), accessTTL); err != nil {
			s.Logger.Error("oauth create grant failed", "error", err)
			oauthError(w, http.StatusInternalServerError, "server_error", "try again later")
			return
		}
	case "refresh_token":
		refresh = random(32)
		var err error
		g, access, err = s.Store.Refresh(r.Context(), mcp.HashToken(f.Get("refresh_token")), mcp.HashToken(refresh), clientID, time.Now().Add(refreshTTL), accessTTL)
		if errors.Is(err, ErrRefreshReuse) {
			s.Logger.Warn("oauth refresh token reused; grant revoked", "client_id", clientID)
		}
		if err != nil {
			oauthError(w, http.StatusBadRequest, "invalid_grant", "the refresh token is invalid, expired or revoked")
			return
		}
		if !s.approverStillAllowed(r.Context(), g) {
			if err := s.Store.RevokeGrantID(r.Context(), g.ID); err != nil {
				s.Logger.Error("oauth revoke after lost access failed", "grant_id", g.ID, "error", err)
			}
			s.Logger.Info("oauth connection ended: its approver no longer has access", "grant_id", g.ID, "account_id", g.AccountID)
			oauthError(w, http.StatusBadRequest, "invalid_grant", "the person who connected this app no longer has access")
			return
		}
	default:
		oauthError(w, http.StatusBadRequest, "unsupported_grant_type", "use authorization_code or refresh_token")
		return
	}
	scope := ScopeRead
	if g.CanWrite {
		scope += " " + ScopeWrite
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"access_token": access, "token_type": "Bearer", "expires_in": int(accessTTL.Seconds()),
		"refresh_token": refresh, "scope": scope,
	})
}

// revoke ends a connection by its refresh token (RFC 7009). Presenting an
// access token does nothing (it expires within the hour); the owner can
// also disconnect an app on the admin page.
func (s *Server) revoke(w http.ResponseWriter, r *http.Request) {
	if !s.other.Allow("revoke:"+ratelimit.ClientIP(r), 30) {
		oauthError(w, http.StatusTooManyRequests, "slow_down", "wait a minute")
		return
	}
	r.Body = http.MaxBytesReader(w, r.Body, 16<<10)
	if err := r.ParseForm(); err != nil {
		oauthError(w, http.StatusBadRequest, "invalid_request", "expected a form body")
		return
	}
	if err := s.Store.RevokeByRefresh(r.Context(), mcp.HashToken(r.PostForm.Get("token")), r.PostForm.Get("client_id")); err != nil && !errors.Is(err, ErrNotFound) {
		s.Logger.Error("oauth revoke failed", "error", err)
	}
	w.WriteHeader(http.StatusOK)
}
