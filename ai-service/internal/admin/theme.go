package admin

import (
	"net/http"
	"strings"
)

const themeCookie = "admin_theme"

// themeOf is "light" or "dark" when the owner picked one, "" to follow the device.
func themeOf(r *http.Request) string {
	c, err := r.Cookie(themeCookie)
	if err != nil {
		return ""
	}
	if c.Value == "light" || c.Value == "dark" {
		return c.Value
	}
	return ""
}

// setTheme stores the colour choice in a cookie and returns to the page the
// switch was pressed on. Only /admin paths are accepted as the way back.
func (h *Handler) setTheme(w http.ResponseWriter, r *http.Request) {
	if err := r.ParseForm(); err != nil {
		http.Error(w, "invalid form", http.StatusBadRequest)
		return
	}
	c := &http.Cookie{Name: themeCookie, Path: "/admin", HttpOnly: true, Secure: r.TLS != nil, SameSite: http.SameSiteStrictMode}
	switch v := r.PostForm.Get("theme"); v {
	case "light", "dark":
		c.Value, c.MaxAge = v, 365*24*60*60
	default: // auto: follow the device
		c.MaxAge = -1
	}
	http.SetCookie(w, c)
	http.Redirect(w, r, backPath(r.PostForm.Get("back")), http.StatusSeeOther)
}

func backPath(p string) string {
	if p == "/admin" || (strings.HasPrefix(p, "/admin/") && !strings.ContainsAny(p, "\\?#") && !strings.Contains(p, "//") && !strings.Contains(p, "..")) {
		return p
	}
	return "/admin"
}
