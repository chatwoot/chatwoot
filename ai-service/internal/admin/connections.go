package admin

import (
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

type appView struct {
	ID       int64
	Name     string
	Access   string
	Created  string
	LastUsed string
	Revoked  bool
}

type connectionsData struct {
	Apps      []appView
	OAuth     bool // apps can connect by signing in
	Enabled   bool
	AccountID int64
	URL       string
	Tokens    []tokenView
	NewToken  string // shown once, right after it is created
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
	if r.URL.Query().Get("done") == "revoked" {
		d.Notice = "Revoked. AI tools using that token are cut off immediately."
	}
	h.renderConnections(w, r, http.StatusOK, d)
}

func (h *Handler) renderConnections(w http.ResponseWriter, r *http.Request, status int, d connectionsData) {
	d.URL = h.mcpURL(r)
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
				v.LastUsed = t.LastUsedAt.In(h.loc()).Format("2 Jan 2006 15:04")
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
			v := appView{ID: g.ID, Name: g.ClientName, Access: "Read only", Created: h.day(g.CreatedAt), LastUsed: "Never", Revoked: !g.RevokedAt.IsZero()}
			if g.CanWrite {
				v.Access = "Read and write"
			}
			if !g.LastUsedAt.IsZero() {
				v.LastUsed = g.LastUsedAt.In(h.loc()).Format("2 Jan 2006 15:04")
			}
			d.Apps = append(d.Apps, v)
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
		h.Logger.Info("mcp token created", "account_id", acct, "token_id", t.ID, "can_write", t.CanWrite, "remote_addr", r.RemoteAddr)
		d.NewToken = plain
		h.renderConnections(w, r, http.StatusOK, d)
	case "revoke_app":
		id, _ := strconv.ParseInt(r.PostForm.Get("id"), 10, 64)
		if h.Apps == nil || h.Apps.RevokeGrant(r.Context(), acct, id) != nil {
			d.Error = "That app is already disconnected or belongs to another account."
			h.renderConnections(w, r, http.StatusUnprocessableEntity, d)
			return
		}
		h.Logger.Info("oauth app revoked", "account_id", acct, "grant_id", id, "remote_addr", r.RemoteAddr)
		http.Redirect(w, r, "/admin/connections?account="+strconv.FormatInt(acct, 10)+"&done=revoked", http.StatusSeeOther)
	case "revoke":
		id, _ := strconv.ParseInt(r.PostForm.Get("id"), 10, 64)
		if err := h.Tokens.Revoke(r.Context(), acct, id); err != nil {
			d.Error = "That token is already revoked or belongs to another account."
			h.renderConnections(w, r, http.StatusUnprocessableEntity, d)
			return
		}
		h.Logger.Info("mcp token revoked", "account_id", acct, "token_id", id, "remote_addr", r.RemoteAddr)
		http.Redirect(w, r, "/admin/connections?account="+strconv.FormatInt(acct, 10)+"&done=revoked", http.StatusSeeOther)
	default:
		http.Error(w, "unknown action", http.StatusBadRequest)
	}
}
