package admin

import (
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
)

func themePost(v url.Values) *http.Request {
	r := httptest.NewRequest(http.MethodPost, "/admin/theme", strings.NewReader(v.Encode()))
	r.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	r.Header.Set("Sec-Fetch-Site", "same-origin")
	r.SetBasicAuth(Username, pw)
	return r
}

func TestTheme_DarkCookieThenPageRendersDark(t *testing.T) {
	// Arrange
	e := setup(t, nil)

	// Act
	rec := e.do(themePost(url.Values{"theme": {"dark"}, "back": {"/admin/knowledge"}}))
	page := httptest.NewRequest(http.MethodGet, "/admin", nil)
	page.SetBasicAuth(Username, pw)
	for _, c := range rec.Result().Cookies() {
		page.AddCookie(c)
	}
	body := e.do(page).Body.String()

	// Assert
	c := rec.Result().Cookies()
	if rec.Code != http.StatusSeeOther || rec.Header().Get("Location") != "/admin/knowledge" {
		t.Fatalf("status=%d location=%q", rec.Code, rec.Header().Get("Location"))
	}
	if len(c) != 1 || c[0].Value != "dark" || !c[0].HttpOnly || c[0].SameSite != http.SameSiteStrictMode || c[0].Path != "/admin" {
		t.Fatalf("cookie = %+v", c)
	}
	if !strings.Contains(body, `<html lang="en" data-theme="dark">`) || !strings.Contains(body, `value="dark" aria-pressed="true"`) {
		t.Fatal("page not rendered in dark theme")
	}
}

func TestTheme_AutoClearsCookie(t *testing.T) {
	// Arrange
	e := setup(t, nil)

	// Act
	rec := e.do(themePost(url.Values{"theme": {"auto"}}))

	// Assert
	c := rec.Result().Cookies()
	if len(c) != 1 || c[0].MaxAge >= 0 {
		t.Fatalf("auto must delete the cookie: %+v", c)
	}
}

func TestTheme_UnknownCookieValueIgnored(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	r := httptest.NewRequest(http.MethodGet, "/admin", nil)
	r.SetBasicAuth(Username, pw)
	r.AddCookie(&http.Cookie{Name: themeCookie, Value: `dark" onload="x`})

	// Act
	body := e.do(r).Body.String()

	// Assert
	if strings.Contains(body, "onload") {
		t.Fatal("a forged cookie value reached the page")
	}
	if strings.Contains(body, `<html lang="en" data-theme`) {
		t.Fatal("unknown theme must fall back to auto")
	}
}

func TestTheme_BackPathOnlyAdmin(t *testing.T) {
	cases := map[string]string{
		"/admin/test": "/admin/test", "/admin": "/admin",
		"https://evil.example": "/admin", "//evil.example": "/admin", "/admin//evil.example": "/admin",
		"/admin/../x": "/admin", "/adminx": "/admin", `/admin\evil`: "/admin", "": "/admin",
	}
	for in, want := range cases {
		// Act
		got := backPath(in)

		// Assert
		if got != want {
			t.Errorf("backPath(%q) = %q, want %q", in, got, want)
		}
	}
}

func TestTheme_RequiresAuthAndSameOrigin(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	noAuth := themePost(url.Values{"theme": {"dark"}})
	noAuth.Header.Del("Authorization")
	cross := themePost(url.Values{"theme": {"dark"}})
	cross.Header.Set("Sec-Fetch-Site", "cross-site")

	// Act
	a, c := e.do(noAuth), e.do(cross)

	// Assert
	if a.Code != http.StatusUnauthorized || c.Code != http.StatusForbidden || len(a.Result().Cookies())+len(c.Result().Cookies()) != 0 {
		t.Fatalf("noauth=%d cross=%d", a.Code, c.Code)
	}
}
