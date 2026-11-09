package admin

import (
	"crypto/rand"
	"encoding/hex"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/cfaccess"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/oauth"
	"net/http"
	"strconv"
	"strings"
	"time"
)

type tokenView struct {
	ID       int64
	Name     string
	Access   string
	Created  string
	LastUsed string
	Expires  string
	Expired  bool
	Revoked  bool
}

type memberView struct {
	Email  string
	Access string
	Added  string
}

type appView struct {
	ID       int64
	By       string
	Name     string
	Access   string
	Created  string
	LastUsed string
	Revoked  bool
}

type connectionsData struct {
	Apps      []appView
	OAuth     bool // apps can connect by signing in
	Team      []memberView
	TeamOn    bool // approvals by team members through Cloudflare Access
	Enabled   bool
	AccountID int64
	URL       string
	Tokens    []tokenView
	NewToken  string // shown once, right after it is created
	Once      string // one-time value in the create form, so a reload cannot create a second token
	NewName   string
	NewWrite  bool
	Notice    string
	Error     string
}

func (h *Handler) mcpURL(r *http.Request) string {
	if h.MCPURL != "" {
		return h.MCPURL
	}
	scheme := "https"
	if host := r.Host; r.TLS == nil && (strings.HasPrefix(host, "127.0.0.1") || strings.HasPrefix(host, "localhost")) {
		scheme = "http"
	}
	return scheme + "://" + r.Host + "/mcp"
}

func (h *Handler) showConnections(w http.ResponseWriter, r *http.Request) {
	d := connectionsData{AccountID: accountParam(r.URL.Query().Get("account"))}
	switch r.URL.Query().Get("done") {
	case "revoked":
		d.Notice = "Revoked. AI tools using that token are cut off immediately."
	case "team":
		d.Notice = "Team updated. Removing someone also disconnects the apps they connected to this account."
	}
	h.renderConnections(w, r, http.StatusOK, d)
}

func (h *Handler) renderConnections(w http.ResponseWriter, r *http.Request, status int, d connectionsData) {
	d.URL = h.mcpURL(r)
	d.Once = h.newOnce()
	if h.Tokens != nil {
		d.Enabled = true
		list, err := h.Tokens.List(r.Context(), d.AccountID)
		if err != nil {
			h.Logger.Error("list mcp tokens", "account_id", d.AccountID, "error", err)
			d.Error = "Could not load the connections. Check the database connection."
		}
		for _, t := range list {
			v := tokenView{ID: t.ID, Name: t.Name, Access: "Read only", Created: h.day(t.CreatedAt),
				LastUsed: "Never", Revoked: !t.RevokedAt.IsZero(), Expires: "Never"}
			if !t.ExpiresAt.IsZero() {
				v.Expires = h.day(t.ExpiresAt)
				v.Expired = t.ExpiresAt.Before(time.Now())
			}
			if t.CanWrite {
				v.Access = "Read and write"
			}
			if !t.LastUsedAt.IsZero() {
				v.LastUsed = h.when(t.LastUsedAt)
			}
			d.Tokens = append(d.Tokens, v)
		}
	}
	if h.Apps != nil {
		d.OAuth = strings.HasPrefix(d.URL, "https://") || strings.HasPrefix(d.URL, "http://127.0.0.1:")
		grants, err := h.Apps.Grants(r.Context(), d.AccountID)
		if err != nil {
			h.Logger.Error("list oauth apps", "account_id", d.AccountID, "error", err)
		}
		for _, g := range grants {
			by := g.ApprovedBy
			if by == "" {
				by = "Owner (admin password)"
			}
			v := appView{ID: g.ID, By: by, Name: g.ClientName, Access: "Read only", Created: h.day(g.CreatedAt), LastUsed: "Never", Revoked: !g.RevokedAt.IsZero()}
			if g.CanWrite {
				v.Access = "Read and write"
			}
			if !g.LastUsedAt.IsZero() {
				v.LastUsed = h.when(g.LastUsedAt)
			}
			d.Apps = append(d.Apps, v)
		}
	}
	if h.Apps != nil && h.TeamSignIn {
		d.TeamOn = true
		team, err := h.Apps.Team(r.Context(), d.AccountID)
		if err != nil {
			h.Logger.Error("list team", "account_id", d.AccountID, "error", err)
		}
		for _, m := range team {
			v := memberView{Email: m.Email, Access: "Read only", Added: h.day(m.CreatedAt)}
			if m.CanWrite {
				v.Access = "Read and write"
			}
			d.Team = append(d.Team, v)
		}
	}
	// The new token is on this page only: never cache it.
	w.Header().Set("Cache-Control", "no-store")
	h.renderPage(w, r, status, "connections.html", d)
}

func (h *Handler) submitConnections(w http.ResponseWriter, r *http.Request) {
	if h.Tokens == nil {
		http.Error(w, "connections need DATABASE_URL", http.StatusServiceUnavailable)
		return
	}
	r.Body = http.MaxBytesReader(w, r.Body, 16<<10)
	if err := r.ParseForm(); err != nil {
		http.Error(w, "invalid form", http.StatusBadRequest)
		return
	}
	acct := accountParam(r.PostForm.Get("account"))
	d := connectionsData{AccountID: acct}
	switch r.PostForm.Get("action") {
	case "create":
		if !h.useOnce(r.PostForm.Get("once")) {
			d.Notice = "That form was already sent (for example by reloading the page), so no token was made this time. If you did not copy a token, create one again below."
			h.renderConnections(w, r, http.StatusOK, d)
			return
		}
		d.NewName, d.NewWrite = strings.TrimSpace(r.PostForm.Get("name")), r.PostForm.Get("access") == "write"
		ttl := 90 * 24 * time.Hour
		switch r.PostForm.Get("expires") {
		case "30":
			ttl = 30 * 24 * time.Hour
		case "365":
			ttl = 365 * 24 * time.Hour
		case "never":
			ttl = 0
		}
		plain, t, err := h.Tokens.Create(r.Context(), acct, d.NewName, d.NewWrite, ttl)
		if err != nil {
			d.Error = err.Error()
			h.renderConnections(w, r, http.StatusUnprocessableEntity, d)
			return
		}
		access := "read only"
		if t.CanWrite {
			access = "read and write"
		}
		h.record(r, acct, "token created", t.Name+" ("+access+")", nil)
		h.Logger.Info("mcp token created", "account_id", acct, "token_id", t.ID, "can_write", t.CanWrite, "remote_addr", r.RemoteAddr)
		d.NewToken = plain
		h.renderConnections(w, r, http.StatusOK, d)
	case "add_member", "remove_member":
		if h.Apps == nil || !h.TeamSignIn {
			http.Error(w, "team sign-in is off", http.StatusBadRequest)
			return
		}
		email, ok := cfaccess.NormalizeEmail(r.PostForm.Get("email"))
		if !ok || !validEmail(email) {
			d.Error = "Enter a valid email address."
			h.renderConnections(w, r, http.StatusUnprocessableEntity, d)
			return
		}
		var err error
		if r.PostForm.Get("action") == "add_member" {
			err = h.Apps.AddMember(r.Context(), oauth.Member{Email: email, AccountID: acct, CanWrite: r.PostForm.Get("member_access") == "write"})
		} else {
			err = h.Apps.RemoveMember(r.Context(), email, acct)
		}
		if err != nil {
			h.Logger.Warn("team change failed", "account_id", acct, "error", err)
			d.Error = "Could not change the team. Try again."
			h.renderConnections(w, r, http.StatusUnprocessableEntity, d)
			return
		}
		summary := email
		if r.PostForm.Get("action") == "add_member" {
			summary += map[bool]string{true: " (read and write)", false: " (read only)"}[r.PostForm.Get("member_access") == "write"]
		}
		h.record(r, acct, strings.ReplaceAll(r.PostForm.Get("action"), "_", " "), summary, nil)
		h.Logger.Info("team changed", "account_id", acct, "action", r.PostForm.Get("action"), "remote_addr", r.RemoteAddr)
		http.Redirect(w, r, "/admin/connections?account="+strconv.FormatInt(acct, 10)+"&done=team", http.StatusSeeOther)
	case "revoke_app":
		id, _ := strconv.ParseInt(r.PostForm.Get("id"), 10, 64)
		if h.Apps == nil || h.Apps.RevokeGrant(r.Context(), acct, id) != nil {
			d.Error = "That app is already disconnected or belongs to another account."
			h.renderConnections(w, r, http.StatusUnprocessableEntity, d)
			return
		}
		h.record(r, acct, "app disconnected", "connection "+strconv.FormatInt(id, 10), nil)
		h.Logger.Info("oauth app revoked", "account_id", acct, "grant_id", id, "remote_addr", r.RemoteAddr)
		http.Redirect(w, r, "/admin/connections?account="+strconv.FormatInt(acct, 10)+"&done=revoked", http.StatusSeeOther)
	case "revoke":
		id, _ := strconv.ParseInt(r.PostForm.Get("id"), 10, 64)
		if err := h.Tokens.Revoke(r.Context(), acct, id); err != nil {
			d.Error = "That token is already revoked or belongs to another account."
			h.renderConnections(w, r, http.StatusUnprocessableEntity, d)
			return
		}
		h.record(r, acct, "token revoked", "token "+strconv.FormatInt(id, 10), nil)
		h.Logger.Info("mcp token revoked", "account_id", acct, "token_id", id, "remote_addr", r.RemoteAddr)
		http.Redirect(w, r, "/admin/connections?account="+strconv.FormatInt(acct, 10)+"&done=revoked", http.StatusSeeOther)
	default:
		http.Error(w, "unknown action", http.StatusBadRequest)
	}
}

// validEmail is a light check; Cloudflare Access proves the address at sign-in.
func validEmail(e string) bool {
	at := strings.LastIndex(e, "@")
	return len(e) <= 254 && at > 0 && at < len(e)-3 && strings.Contains(e[at:], ".") && !strings.ContainsAny(e, " \t<>\"'")
}

// newOnce issues a one-time form value; useOnce consumes it. At most 1000
// are kept, oldest first out, each valid for an hour.
func (h *Handler) newOnce() string {
	b := make([]byte, 16)
	_, _ = rand.Read(b)
	v := hex.EncodeToString(b)
	h.onceMu.Lock()
	defer h.onceMu.Unlock()
	if h.once == nil {
		h.once = map[string]time.Time{}
	}
	if len(h.once) >= 1000 {
		var oldest string
		for k, t := range h.once {
			if oldest == "" || t.Before(h.once[oldest]) {
				oldest = k
			}
		}
		delete(h.once, oldest)
	}
	h.once[v] = time.Now()
	return v
}

func (h *Handler) useOnce(v string) bool {
	h.onceMu.Lock()
	defer h.onceMu.Unlock()
	t, ok := h.once[v]
	delete(h.once, v)
	return ok && time.Since(t) < time.Hour
}
