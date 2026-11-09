package admin

import (
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
	"time"
)

// Guards for the consistent admin UI (refs #1): one button system, one card
// title style, one date format, and a phone menu on every page.

func templateSources(t *testing.T) map[string]string {
	t.Helper()
	files, err := filepath.Glob("*.html")
	if err != nil || len(files) == 0 {
		t.Fatalf("no templates: %v", err)
	}
	out := map[string]string{}
	for _, f := range files {
		b, err := os.ReadFile(f)
		if err != nil {
			t.Fatal(err)
		}
		out[f] = string(b)
	}
	return out
}

func TestUI_NoLinkStyledOrInlineStyledControls(t *testing.T) {
	// Arrange
	sources := templateSources(t)
	inlineTitle := regexp.MustCompile(`<h[23][^>]*style="font-size`)

	for name, src := range sources {
		// Act and Assert
		if strings.Contains(src, `class="link"`) {
			t.Errorf("%s: destructive actions must use class=\"btn small danger\", not a link-styled button", name)
		}
		if inlineTitle.MatchString(src) {
			t.Errorf("%s: card titles must use class=\"card-title\", not an inline font-size", name)
		}
	}
}

func TestUI_ButtonKindsAreDefined(t *testing.T) {
	// Arrange
	css := templateSources(t)["layout.html"]

	// Act and Assert
	for _, rule := range []string{".primary", ".danger", ".card-title", ".card-foot", "details.menu"} {
		if !strings.Contains(css, rule) {
			t.Errorf("layout.html has no %s rule", rule)
		}
	}
}

func TestUI_EveryPageHasThePhoneMenu(t *testing.T) {
	// Arrange
	e := setup(t, nil)

	for _, path := range adminPages {
		r := httptest.NewRequest(http.MethodGet, path, nil)
		r.SetBasicAuth(Username, pw)

		// Act
		body := e.do(r).Body.String()

		// Assert
		i := strings.Index(body, `<details class="menu"`)
		if i < 0 {
			t.Errorf("%s: no phone menu", path)
			continue
		}
		menu := body[i:]
		menu = menu[:strings.Index(menu, "</details>")]
		for _, link := range adminPages {
			if !strings.Contains(menu, `href="`+link+`"`) {
				t.Errorf("%s: phone menu misses %s", path, link)
			}
		}
		if !strings.Contains(menu, `name="theme"`) {
			t.Errorf("%s: phone menu has no theme switch", path)
		}
	}
}

func TestUI_ConnectionsExplainsApprovals(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	e.h.Tokens = &memTokens{}
	r := httptest.NewRequest(http.MethodGet, "/admin/connections?account=1", nil)
	r.SetBasicAuth(Username, pw)

	// Act
	body := e.do(r).Body.String()

	// Assert
	if !strings.Contains(body, `href="/admin/approvals?account=1"`) {
		t.Error("connections page does not link to AI approvals")
	}
	if !strings.Contains(body, "wait for your approval") {
		t.Error("connections page does not say write access waits for approval")
	}
}

func TestUI_OneDateFormat(t *testing.T) {
	// Arrange
	h := &Handler{Location: time.UTC}
	at := time.Date(2026, 11, 10, 2, 19, 0, 0, time.UTC)

	// Act
	when, day := h.when(at), h.day(at)

	// Assert
	if when != "10 Nov 2026, 02:19" || day != "10 Nov 2026" {
		t.Fatalf("when = %q, day = %q", when, day)
	}
}

func TestUI_HiddenStaysHiddenAndMenuClosesOnFocusLeave(t *testing.T) {
	// Arrange
	sources := templateSources(t)
	js, err := os.ReadFile("static/admin.js")
	if err != nil {
		t.Fatal(err)
	}

	// Act and Assert: buttons get display:inline-flex, so [hidden] needs !important
	if !strings.Contains(sources["layout.html"], "[hidden] { display: none !important; }") {
		t.Error("layout.html must keep [hidden] elements hidden over the button display rule")
	}
	if !strings.Contains(string(js), "details.menu") || !strings.Contains(string(js), "'Escape'") {
		t.Error("admin.js must close the phone menu when focus leaves it and on Escape")
	}
}

func TestUI_ProvidersEnterSaves(t *testing.T) {
	// Arrange
	src := templateSources(t)["page.html"]

	// Act
	save := strings.Index(src, `>Save settings</button>`)
	test := strings.Index(src, `name="test"`)

	// Assert: implicit submission uses the first submit button in the form
	if save < 0 || test < 0 || save > strings.Index(src, `{{define "provider"}}`) || save > strings.Index(src, `{{template "provider"`) {
		t.Fatalf("a Save submit must come before the per-card Test buttons (save=%d test=%d)", save, test)
	}
}
