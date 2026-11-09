package admin

import (
	"net/http"
	"strconv"
	"strings"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/profile"
)

// maxProfileForm bounds a business profile post. Urlencoded Thai is 9 bytes
// per character, so every field at its limit is (120 + 4×4,000) × 9 ≈ 145 KB.
const maxProfileForm = 256 << 10

type businessData struct {
	Enabled bool // a database is configured
	Profile profile.Profile
	Updated string
	Saved   bool
	Error   string
	Limits  struct{ Name, Field int }
}

func (h *Handler) showBusiness(w http.ResponseWriter, r *http.Request) {
	acct := accountParam(r.URL.Query().Get("account"))
	data := businessData{Enabled: h.Profiles != nil, Profile: profile.Profile{AccountID: acct},
		Saved: r.URL.Query().Get("done") == "saved"}
	if h.Profiles != nil {
		p, err := h.Profiles.Get(r.Context(), acct)
		if err != nil {
			h.Logger.Error("load business profile", "account_id", acct, "error", err)
			data.Error = "Could not load the business profile. Check the database connection."
		} else {
			data.Profile = p
		}
	}
	h.renderBusiness(w, r, http.StatusOK, data)
}

func (h *Handler) submitBusiness(w http.ResponseWriter, r *http.Request) {
	if h.Profiles == nil {
		http.Error(w, "business profiles disabled: set DATABASE_URL", http.StatusServiceUnavailable)
		return
	}
	r.Body = http.MaxBytesReader(w, r.Body, maxProfileForm)
	if err := r.ParseForm(); err != nil {
		http.Error(w, "form too large or invalid", http.StatusBadRequest)
		return
	}
	f := r.PostForm
	// Parse strictly: falling back to account 1 here would overwrite its profile.
	acct, err := strconv.ParseInt(strings.TrimSpace(f.Get("account")), 10, 64)
	if err != nil || acct < 1 {
		http.Error(w, "account must be a positive number", http.StatusBadRequest)
		return
	}
	p := profile.Profile{
		AccountID:    acct,
		BusinessName: f.Get("business_name"), About: f.Get("about"), Tone: f.Get("tone"),
		Contact: f.Get("contact"), Rules: f.Get("rules"),
		// An unticked checkbox is simply absent from the form: absent = off.
		Features: profile.Features{
			Voice: f.Get("feature_voice") == "on", Images: f.Get("feature_images") == "on", Stickers: f.Get("feature_stickers") == "on",
		},
	}.Normalize()
	if err := h.Profiles.Save(r.Context(), p); err != nil {
		h.Logger.Warn("save business profile failed", "account_id", p.AccountID, "error", err)
		h.renderBusiness(w, r, http.StatusUnprocessableEntity, businessData{Enabled: true, Profile: p, Error: err.Error()})
		return
	}
	h.record(r, p.AccountID, "business profile saved", p.BusinessName, nil)
	h.Logger.Info("business profile saved", "account_id", p.AccountID, "remote_addr", r.RemoteAddr)
	http.Redirect(w, r, "/admin/business?account="+strconv.FormatInt(p.AccountID, 10)+"&done=saved", http.StatusSeeOther)
}

func (h *Handler) renderBusiness(w http.ResponseWriter, r *http.Request, status int, data businessData) {
	data.Limits.Name, data.Limits.Field = profile.MaxNameRunes, profile.MaxFieldRunes
	if !data.Profile.UpdatedAt.IsZero() {
		data.Updated = h.when(data.Profile.UpdatedAt)
	}
	h.renderPage(w, r, status, "business.html", data)
}
