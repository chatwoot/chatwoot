package admin

import (
	"html"
	"net/http"
	"net/http/httptest"
	"regexp"
	"strings"
	"testing"
)

var adminPages = []string{"/admin", "/admin/providers", "/admin/test", "/admin/business", "/admin/knowledge", "/admin/approvals", "/admin/comments", "/admin/connections"}

func TestBrand_EveryPageShowsProntoLogoFaviconAndTitle(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	title := regexp.MustCompile(`<title>[^<]+ · Pronto</title>`)

	for _, path := range adminPages {
		r := httptest.NewRequest(http.MethodGet, path, nil)
		r.SetBasicAuth(Username, pw)

		// Act
		rec := e.do(r)
		body := rec.Body.String()

		// Assert
		if rec.Code != http.StatusOK {
			t.Fatalf("%s: status %d", path, rec.Code)
		}
		if !strings.Contains(body, `aria-label="Pronto"`) || !strings.Contains(body, "AI admin") {
			t.Errorf("%s: no Pronto wordmark in the sidebar", path)
		}
		if !strings.Contains(html.UnescapeString(body), `<link rel="icon" type="image/svg+xml" href="data:image/svg+xml;base64,`) {
			t.Errorf("%s: no Pronto favicon", path)
		}
		if !title.MatchString(body) {
			t.Errorf("%s: title does not end in ' · Pronto'", path)
		}
		if strings.Contains(body, "ai-service <span>admin</span>") {
			t.Errorf("%s: old ai-service wordmark still shown", path)
		}
	}
}

func TestBrand_ProntoColoursInBothThemes(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	r := httptest.NewRequest(http.MethodGet, "/admin", nil)
	r.SetBasicAuth(Username, pw)

	// Act
	body := strings.ToLower(e.do(r).Body.String())

	// Assert
	for _, want := range []string{"--accent: #3300aa", "--brand: #3300aa", "--accent: #c9c2ff", "--brand: #c9c2ff"} {
		if !strings.Contains(body, want) {
			t.Errorf("missing %q", want)
		}
	}
	if strings.Contains(body, "#1f6feb") || strings.Contains(body, "#4c8dff") {
		t.Error("old blue accent still present")
	}
}

func TestBrand_CSPAllowsOnlyDataImages(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	r := httptest.NewRequest(http.MethodGet, "/admin", nil)
	r.SetBasicAuth(Username, pw)

	// Act
	csp := e.do(r).Header().Get("Content-Security-Policy")

	// Assert
	if !strings.Contains(csp, "img-src data:;") || !strings.Contains(csp, "default-src 'none'") {
		t.Fatalf("CSP = %s", csp)
	}
	if regexp.MustCompile(`img-src[^;]*(\*|https?:|'self')`).MatchString(csp) {
		t.Errorf("img-src wider than data: %s", csp)
	}
}

func TestBrand_LoginPromptNamesPronto_AndRejectedRequestShowsNoPage(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	r := httptest.NewRequest(http.MethodGet, "/admin", nil)
	r.SetBasicAuth(Username, "wrong")

	// Act
	rec := e.do(r)

	// Assert
	if rec.Code != http.StatusUnauthorized || !strings.Contains(rec.Header().Get("WWW-Authenticate"), `realm="Pronto AI admin"`) {
		t.Fatalf("status=%d auth=%q", rec.Code, rec.Header().Get("WWW-Authenticate"))
	}
	if strings.Contains(rec.Body.String(), `aria-label="Pronto"`) {
		t.Error("rejected request rendered the page")
	}
}
