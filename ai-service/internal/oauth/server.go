package oauth

import (
	"crypto/sha256"
	"crypto/subtle"
	"embed"
	"encoding/base64"
	"encoding/json"
	"errors"
	"html/template"
	"log/slog"
	"net"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/mcp"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/ratelimit"
)

// Scopes.
const (
	ScopeRead  = "kb:read"
	ScopeWrite = "kb:write"
)

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
	Password string // the admin password approves each app
	Store    Store
	Logger   *slog.Logger

	// login counts password attempts only, so other endpoints cannot fill
	// its table; other counts registrations and token calls.
	login, other ratelimit.Limiter
}

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
	mux.HandleFunc("GET /.well-known/oauth-protected-resource", s.resourceMetadata)
	mux.HandleFunc("GET /.well-known/oauth-protected-resource/mcp", s.resourceMetadata)
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

func clientIP(r *http.Request) string {
	if host, _, err := net.SplitHostPort(r.RemoteAddr); err == nil {
		return host
	}
	return r.RemoteAddr
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
	if !s.other.Allow("register:"+clientIP(r), 10) || !s.other.Allow("register", 60) {
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
	name := strings.TrimSpace(req.ClientName)
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
	Error      string
	Account    string
	Write      bool
}

func (s *Server) render(w http.ResponseWriter, status int, d pageData) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Header().Set("Cache-Control", "no-store")
	w.Header().Set("X-Frame-Options", "DENY")
	w.Header().Set("Referrer-Policy", "no-referrer")
	formAction := "'self'"
	if u, err := url.Parse(d.RedirectURI); err == nil && d.Error == "" && u.Host != "" {
		formAction += " " + u.Scheme + "://" + u.Host // the approval redirects there
	}
	w.Header().Set("Content-Security-Policy", "default-src 'none'; style-src 'unsafe-inline'; form-action "+formAction+"; frame-ancestors 'none'; base-uri 'none'")
	w.WriteHeader(status)
	if err := consent.Execute(w, d); err != nil {
		s.Logger.Error("render consent page", "error", err)
	}
}

func (s *Server) authorizePage(w http.ResponseWriter, r *http.Request) {
	a, problem := s.parseAuth(r, r.URL.Query())
	d := pageData{authRequest: a, ClientID: a.Client.ID, Error: problem, Account: "1", Write: a.WantsWrite}
	if u, err := url.Parse(a.RedirectURI); err == nil {
		d.ReturnHost = u.Host
	}
	status := http.StatusOK
	if problem != "" {
		status = http.StatusBadRequest
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
	d := pageData{authRequest: a, ClientID: a.Client.ID, Error: problem, Account: f.Get("account"), Write: f.Get("access") == "write"}
	if u, err := url.Parse(a.RedirectURI); err == nil {
		d.ReturnHost = u.Host
	}
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
	if !s.login.Allow("login:"+clientIP(r), 5) || !s.login.Allow("login", 20) {
		d.Error = "Too many attempts. Wait a minute and try again."
		s.render(w, http.StatusTooManyRequests, d)
		return
	}
	want := sha256.Sum256([]byte(s.Password))
	got := sha256.Sum256([]byte(f.Get("password")))
	if s.Password == "" || subtle.ConstantTimeCompare(want[:], got[:]) != 1 {
		s.Logger.Warn("oauth approval: wrong password", "client_id", a.Client.ID, "remote_addr", r.RemoteAddr)
		d.Error = "Wrong password."
		s.render(w, http.StatusUnauthorized, d)
		return
	}
	acct, err := strconv.ParseInt(strings.TrimSpace(d.Account), 10, 64)
	if err != nil || acct < 1 {
		d.Error = "Account must be a positive number."
		s.render(w, http.StatusUnprocessableEntity, d)
		return
	}
	code := random(32)
	if err := s.Store.SaveCode(r.Context(), Code{Hash: mcp.HashToken(code), ClientID: a.Client.ID, RedirectURI: a.RedirectURI,
		Challenge: a.Challenge, Resource: s.Resource, AccountID: acct, CanWrite: d.Write, ExpiresAt: time.Now().Add(codeTTL)}); err != nil {
		s.Logger.Error("oauth save code failed", "error", err)
		d.Error = "Something went wrong. Try again."
		s.render(w, http.StatusInternalServerError, d)
		return
	}
	s.Logger.Info("oauth app approved", "client_id", a.Client.ID, "account_id", acct, "can_write", d.Write, "remote_addr", r.RemoteAddr)
	q.Set("code", code)
	redirect.RawQuery = q.Encode()
	http.Redirect(w, r, redirect.String(), http.StatusSeeOther)
}

func pkceOK(verifier, challenge string) bool {
	if len(verifier) < 43 || len(verifier) > 128 {
		return false
	}
	sum := sha256.Sum256([]byte(verifier))
	return subtle.ConstantTimeCompare([]byte(base64.RawURLEncoding.EncodeToString(sum[:])), []byte(challenge)) == 1
}

func (s *Server) token(w http.ResponseWriter, r *http.Request) {
	if !s.other.Allow("token:"+clientIP(r), 60) {
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
	var refresh string
	switch f.Get("grant_type") {
	case "authorization_code":
		c, err := s.Store.TakeCode(r.Context(), mcp.HashToken(f.Get("code")))
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
			RefreshExpiresAt: time.Now().Add(refreshTTL)}
		if g.ID, err = s.Store.CreateGrant(r.Context(), g, mcp.HashToken(refresh)); err != nil {
			s.Logger.Error("oauth create grant failed", "error", err)
			oauthError(w, http.StatusInternalServerError, "server_error", "try again later")
			return
		}
	case "refresh_token":
		refresh = random(32)
		var err error
		g, err = s.Store.RotateRefresh(r.Context(), mcp.HashToken(f.Get("refresh_token")), mcp.HashToken(refresh), clientID, time.Now().Add(refreshTTL))
		if errors.Is(err, ErrRefreshReuse) {
			s.Logger.Warn("oauth refresh token reused; grant revoked", "client_id", clientID)
		}
		if err != nil {
			oauthError(w, http.StatusBadRequest, "invalid_grant", "the refresh token is invalid, expired or revoked")
			return
		}
	default:
		oauthError(w, http.StatusBadRequest, "unsupported_grant_type", "use authorization_code or refresh_token")
		return
	}
	access, err := s.Store.IssueAccess(r.Context(), g, accessTTL)
	if err != nil {
		s.Logger.Error("oauth issue access failed", "error", err)
		oauthError(w, http.StatusInternalServerError, "server_error", "try again later")
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

// revoke ends a connection by its refresh token (RFC 7009). Access tokens
// expire within the hour; the owner can also revoke on the admin page.
func (s *Server) revoke(w http.ResponseWriter, r *http.Request) {
	r.Body = http.MaxBytesReader(w, r.Body, 16<<10)
	if err := r.ParseForm(); err != nil {
		oauthError(w, http.StatusBadRequest, "invalid_request", "expected a form body")
		return
	}
	if err := s.Store.RevokeByRefresh(r.Context(), mcp.HashToken(r.PostForm.Get("token")), r.PostForm.Get("client_id")); err != nil {
		s.Logger.Error("oauth revoke failed", "error", err)
	}
	w.WriteHeader(http.StatusOK)
}
