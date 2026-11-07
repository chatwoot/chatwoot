package admin

import (
	"io/fs"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
	"net/http"
	"net/http/httptest"
	"regexp"
	"strings"
	"testing"
)

func TestScript_ServedWithStrictCSP(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	r := httptest.NewRequest(http.MethodGet, "/admin/static/admin.js", nil)
	r.SetBasicAuth(Username, pw)

	// Act
	rec := e.do(r)

	// Assert
	h := rec.Header()
	if rec.Code != http.StatusOK || !strings.HasPrefix(h.Get("Content-Type"), "text/javascript") || h.Get("X-Content-Type-Options") != "nosniff" {
		t.Fatalf("code=%d type=%q nosniff=%q", rec.Code, h.Get("Content-Type"), h.Get("X-Content-Type-Options"))
	}
	for _, want := range []string{"script-src 'self'", "require-trusted-types-for 'script'", "trusted-types 'none'", "default-src 'none'"} {
		if !strings.Contains(h.Get("Content-Security-Policy"), want) {
			t.Errorf("CSP missing %q: %s", want, h.Get("Content-Security-Policy"))
		}
	}
	if strings.Contains(h.Get("Content-Security-Policy"), "unsafe-eval") || strings.Contains(h.Get("Content-Security-Policy"), "script-src 'self' 'unsafe-inline'") {
		t.Error("CSP allows inline scripts or eval")
	}
}

func TestScript_RequiresAuth(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	wrong := httptest.NewRequest(http.MethodGet, "/admin/static/admin.js", nil)
	wrong.SetBasicAuth(Username, "wrong")
	none := httptest.NewRequest(http.MethodGet, "/admin/static/admin.js", nil)

	for name, r := range map[string]*http.Request{"wrong password": wrong, "no credentials": none} {
		// Act
		rec := e.do(r)

		// Assert
		if rec.Code != http.StatusUnauthorized || strings.Contains(rec.Body.String(), "clipboard") {
			t.Errorf("%s: code=%d, want 401 and no script", name, rec.Code)
		}
	}
}

func TestConfirm_HostileTitleIsEscaped(t *testing.T) {
	// Arrange
	mux, ms := knowledgeEnv(t, true)
	ms.docs = append(ms.docs, knowledge.Document{ID: 1, AccountID: 1, Kind: "text",
		Title: `x" onclick="alert(1)"><script src=/admin/static/admin.js></script>`, Content: "c"})

	// Act
	body := kget(mux, "/admin/knowledge?account=1")

	// Assert
	if strings.Count(body, "<script") != 1 {
		t.Errorf("hostile title produced a script tag: %d tags", strings.Count(body, "<script"))
	}
	if strings.Contains(body, `" onclick="`) || !strings.Contains(body, `data-confirm="Delete “x&#34; onclick=&#34;alert(1)&#34;&gt;&lt;script`) {
		t.Error("data-confirm value not escaped as expected")
	}
}

// The CSP is the real wall; these guards keep the code from needing a
// weaker one later.
func TestScript_NoUnsafeSinks(t *testing.T) {
	// Arrange
	banned := regexp.MustCompile(`innerHTML|outerHTML|insertAdjacentHTML|document\.write|\beval\(|new Function|setTimeout\(\s*['"]|setInterval\(\s*['"]`)

	// Act
	found := banned.FindAllString(string(adminJS), -1)

	// Assert
	if len(found) > 0 {
		t.Errorf("admin.js uses %v", found)
	}
}

func TestTemplates_NoInlineScriptsOrHandlers(t *testing.T) {
	// Arrange
	scriptTag := regexp.MustCompile(`(?is)<script\b([^>]*)>(.*?)</script>`)
	handler := regexp.MustCompile(`(?i)<[^>]*[\s/"']on[a-z]+\s*=|javascript:|srcdoc|<base\b|http-equiv|<object\b|<embed\b|<iframe\b`)
	files, err := fs.Glob(pageFS, "*.html")
	if err != nil || len(files) == 0 {
		t.Fatalf("templates: %v %v", files, err)
	}

	for _, f := range files {
		// Act
		b, _ := fs.ReadFile(pageFS, f)
		page := string(b)

		// Assert
		for _, m := range scriptTag.FindAllStringSubmatch(page, -1) {
			if !strings.Contains(m[1], `src="/admin/static/`) || strings.TrimSpace(m[2]) != "" {
				t.Errorf("%s has an inline script: %q", f, m[0])
			}
		}
		if strings.Count(strings.ToLower(page), "<script") != len(scriptTag.FindAllString(page, -1)) {
			t.Errorf("%s has an unclosed script tag", f)
		}
		if m := handler.FindString(page); m != "" {
			t.Errorf("%s has an inline handler: %q", f, m)
		}
	}
}

func TestPages_ConfirmAndCopyHooks(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	r := httptest.NewRequest(http.MethodGet, "/admin", nil)
	r.SetBasicAuth(Username, pw)

	// Act
	rec := e.do(r)

	// Assert
	if !strings.Contains(rec.Body.String(), `<script src="/admin/static/admin.js" defer></script>`) {
		t.Error("pages do not load admin.js")
	}
}
