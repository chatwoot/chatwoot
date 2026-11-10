package admin

import (
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
)

func libraryDocs() []knowledge.Document {
	now := time.Now()
	return []knowledge.Document{
		{ID: 1, AccountID: 1, Kind: knowledge.KindFAQ, Title: "Opening hours", Content: "9 to 6 every day", UpdatedAt: now, UseCount: 4, LastUsedAt: now},
		{ID: 2, AccountID: 1, Kind: knowledge.KindText, Title: "Shipping policy", Content: "Free RETURNS within 7 days", UpdatedAt: now},
		{ID: 3, AccountID: 1, Kind: knowledge.KindText, Title: "Promo page", Content: "November sale", UpdatedAt: now, SourceKey: "web:https://shop.test/promo"},
		{ID: 4, AccountID: 1, Kind: knowledge.KindFAQ, Title: "Old price", Content: "was 100", UpdatedAt: now, ValidUntil: now.Add(-time.Hour)},
		{ID: 9, AccountID: 2, Kind: knowledge.KindFAQ, Title: "Other account", Content: "x", UpdatedAt: now},
	}
}

func getPage(t *testing.T, mux *http.ServeMux, target string) string {
	t.Helper()
	r := httptest.NewRequest(http.MethodGet, target, nil)
	r.SetBasicAuth(Username, pw)
	rec := serve(mux, r)
	if rec.Code != http.StatusOK {
		t.Fatalf("GET %s: code=%d", target, rec.Code)
	}
	return rec.Body.String()
}

func TestLibrary_ParseKeepsOnlyKnownValues(t *testing.T) {
	// Arrange
	q := url.Values{"q": {"  " + strings.Repeat("ก", 300) + "  "}, "type": {"evil"}, "show": {"unused"}, "view": {"table"}}

	// Act
	f := parseLibrary(q)

	// Assert
	if f.Type != "" || f.Show != "unused" || f.View != "" {
		t.Errorf("filter = %+v", f)
	}
	if n := len([]rune(f.Query)); n != maxQueryRunes {
		t.Errorf("query runes = %d, want %d", n, maxQueryRunes)
	}
	if got := parseLibrary(url.Values{"view": {"list"}, "type": {"synced"}}); got.View != "list" || got.Type != "synced" {
		t.Errorf("list/synced dropped: %+v", got)
	}
}

func TestLibrary_ParamsAreEncodedAndOnlyNonDefault(t *testing.T) {
	// Arrange
	f := libraryFilter{Query: "ส่ง & คืน", Type: "faq", View: "list"}

	// Act
	got := f.Params()

	// Assert
	if got != "&q=%E0%B8%AA%E0%B9%88%E0%B8%87+%26+%E0%B8%84%E0%B8%B7%E0%B8%99&type=faq&view=list" {
		t.Errorf("params = %q", got)
	}
	if (libraryFilter{}).Params() != "" {
		t.Error("default filter should add no params")
	}
}

func TestKnowledge_LibraryShowsCountsAsGrid(t *testing.T) {
	// Arrange
	mux, ms := knowledgeEnv(t, true)
	ms.docs = libraryDocs()

	// Act
	body := getPage(t, mux, "/admin/knowledge?account=1")

	// Assert
	for _, want := range []string{
		`class="library"`, `id="doc-1"`, `id="doc-4"`,
		`<span class="stat-num">4</span> <span class="stat-label">Total</span>`,
		`<span class="stat-num">2</span> <span class="stat-label">FAQs</span>`,
		`<span class="stat-num">1</span> <span class="stat-label">Documents</span>`,
		`<span class="stat-num">1</span> <span class="stat-label">From website or file</span>`,
		`<span class="stat-num">3</span> <span class="stat-label">Not used yet</span>`,
		`<span class="stat-num">1</span> <span class="stat-label">Expired or scheduled</span>`,
	} {
		if !strings.Contains(body, want) {
			t.Errorf("missing %s", want)
		}
	}
	if strings.Contains(body, "Other account") {
		t.Error("another account's document is listed")
	}
}

func TestKnowledge_LibraryFiltersBySearchAndType(t *testing.T) {
	// Arrange
	mux, ms := knowledgeEnv(t, true)
	ms.docs = libraryDocs()

	// Act
	search := getPage(t, mux, "/admin/knowledge?account=1&q=returns")
	faqs := getPage(t, mux, "/admin/knowledge?account=1&type=faq")
	synced := getPage(t, mux, "/admin/knowledge?account=1&type=synced")

	// Assert
	if !strings.Contains(search, "Shipping policy") || strings.Contains(search, "Opening hours") {
		t.Error("search should match text case-insensitively and hide the rest")
	}
	if !strings.Contains(search, "1 of 4 shown") {
		t.Error("search result count missing")
	}
	if !strings.Contains(faqs, `id="doc-1"`) || !strings.Contains(faqs, `id="doc-4"`) || strings.Contains(faqs, `id="doc-2"`) {
		t.Error("type=faq should list FAQs only")
	}
	if !strings.Contains(synced, `id="doc-3"`) || strings.Contains(synced, `id="doc-1"`) {
		t.Error("type=synced should list website and file documents only")
	}
}

func TestKnowledge_LibraryListViewKeepsTable(t *testing.T) {
	// Arrange
	mux, ms := knowledgeEnv(t, true)
	ms.docs = libraryDocs()

	// Act
	body := getPage(t, mux, "/admin/knowledge?account=1&view=list&type=faq")

	// Assert
	if !strings.Contains(body, `<tr id="doc-1"`) || strings.Contains(body, `class="library"`) {
		t.Error("list view should render the table, not the grid")
	}
	if !strings.Contains(body, `href="/admin/knowledge?account=1&amp;type=faq" aria-current="false">Grid`) {
		t.Error("grid switch should keep the other filters")
	}
}

func TestKnowledge_EditIsItsOwnPage(t *testing.T) {
	// Arrange
	mux, ms := knowledgeEnv(t, true)
	ms.docs = libraryDocs()

	// Act
	body := getPage(t, mux, "/admin/knowledge?account=1&edit=2&type=doc&view=list")

	// Assert
	if !strings.Contains(body, `id="edit-title"`) {
		t.Fatal("edit form missing")
	}
	for _, gone := range []string{`id="list-title"`, `id="faq-title"`, `id="web-title"`} {
		if strings.Contains(body, gone) {
			t.Errorf("edit page should not show %s", gone)
		}
	}
	back := `href="/admin/knowledge?account=1&amp;type=doc&amp;view=list#doc-2"`
	if strings.Count(body, back) < 2 { // "Back to library" and Cancel
		t.Errorf("back links should return to the same card: %s", back)
	}
	for _, hidden := range []string{`name="type" value="doc"`, `name="view" value="list"`} {
		if !strings.Contains(body, hidden) {
			t.Errorf("save form should carry %s", hidden)
		}
	}
}

func TestKnowledge_SaveAndDeleteReturnToTheLibraryView(t *testing.T) {
	// Arrange
	mux, ms := knowledgeEnv(t, true)
	ms.docs = libraryDocs()
	update := url.Values{"action": {"update"}, "account": {"1"}, "id": {"2"}, "title": {"Shipping"}, "content": {"New text"},
		"type": {"doc"}, "view": {"list"}, "q": {"ship"}, "show": {"https://evil.test"}}
	del := url.Values{"action": {"delete"}, "account": {"1"}, "id": {"4"}, "type": {"faq"}}

	// Act
	saved := serve(mux, kform(update))
	deleted := serve(mux, kform(del))

	// Assert
	if loc := saved.Header().Get("Location"); loc != "/admin/knowledge?account=1&q=ship&type=doc&view=list&done=updated&chunks=1#doc-2" {
		t.Errorf("update Location = %q", loc)
	}
	if loc := deleted.Header().Get("Location"); loc != "/admin/knowledge?account=1&type=faq&done=deleted" {
		t.Errorf("delete Location = %q", loc)
	}
}
