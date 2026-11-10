package admin

import (
	"context"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strconv"
	"strings"
	"testing"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/webfetch"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/websync"
)

type memWeb struct{ srcs []websync.Source }

func (m *memWeb) Add(_ context.Context, acct int64, u, kind string) (websync.Source, error) {
	for _, s := range m.srcs {
		if s.AccountID == acct && s.URL == u {
			return websync.Source{}, websync.ErrDuplicate
		}
	}
	s := websync.Source{ID: int64(len(m.srcs) + 1), AccountID: acct, URL: u, Status: "new", Kind: kind}
	m.srcs = append(m.srcs, s)
	return s, nil
}
func (m *memWeb) List(_ context.Context, acct int64) ([]websync.Source, error) {
	var out []websync.Source
	for _, s := range m.srcs {
		if s.AccountID == acct {
			out = append(out, s)
		}
	}
	return out, nil
}
func (m *memWeb) Get(_ context.Context, acct, id int64) (websync.Source, error) {
	for _, s := range m.srcs {
		if s.ID == id && s.AccountID == acct {
			return s, nil
		}
	}
	return websync.Source{}, websync.ErrNotFound
}
func (m *memWeb) Remove(_ context.Context, acct, id int64) error {
	for i, s := range m.srcs {
		if s.ID == id && s.AccountID == acct {
			m.srcs = append(m.srcs[:i], m.srcs[i+1:]...)
			return nil
		}
	}
	return websync.ErrNotFound
}
func (m *memWeb) Claim(context.Context, int) ([]websync.Source, error) { return nil, nil }
func (m *memWeb) SetInterval(_ context.Context, acct, id int64, h int) error {
	for i, s := range m.srcs {
		if s.ID == id && s.AccountID == acct {
			m.srcs[i].IntervalHours = h
			return nil
		}
	}
	return websync.ErrNotFound
}
func (m *memWeb) MarkAllDue(_ context.Context, acct int64) (int, error) {
	n := 0
	for _, s := range m.srcs {
		if s.AccountID == acct {
			n++
		}
	}
	return n, nil
}
func (m *memWeb) ClaimOne(ctx context.Context, acct, id int64) (websync.Source, error) {
	return m.Get(ctx, acct, id)
}
func (m *memWeb) Save(_ context.Context, s websync.Source) error {
	for i, cur := range m.srcs {
		if cur.ID == s.ID {
			m.srcs[i] = s
		}
	}
	return nil
}

type fixedPage struct{}

func (fixedPage) FetchData(context.Context, string) (webfetch.Page, error) {
	return webfetch.Page{ContentType: "text/csv", Body: []byte("id,question,answer\nfaq-1,Open hours?,9 to 6\nfaq-2,Refunds?,No refunds for digital goods\n")}, nil
}

func (fixedPage) Fetch(context.Context, string) (webfetch.Page, error) {
	return webfetch.Page{ContentType: "text/html", Body: []byte("<title>Refund policy</title><main><p>No refunds for digital goods.</p></main>")}, nil
}

func webEnv(t *testing.T) (*http.ServeMux, *memStore, *memWeb) {
	t.Helper()
	e := setup(t, nil)
	ms := &memStore{}
	kb := &knowledge.Service{Store: ms, Embedder: constEmbedder{"m1"}, TopK: 4, ChunkRunes: 800}
	mw := &memWeb{}
	e.h.Knowledge, e.h.Web = kb, mw
	e.h.WebSync = &websync.Syncer{Store: mw, Knowledge: kb, Fetcher: fixedPage{}, Logger: e.h.Logger,
		Background: func(f func()) { f() }}
	return e.mux, ms, mw
}

func TestWeb_AddIndexesNowAndRefusesInternalAddresses(t *testing.T) {
	// Arrange
	mux, ms, mw := webEnv(t)

	// Act
	added := serve(mux, kform(url.Values{"action": {"add_page"}, "account": {"1"}, "url": {"https://www.johnstockeraistudio.com/legal/refund"}}))
	again := serve(mux, kform(url.Values{"action": {"add_page"}, "account": {"1"}, "url": {"https://www.johnstockeraistudio.com/legal/refund"}}))
	var refused []int
	for _, u := range []string{"http://127.0.0.1:18080/admin", "http://169.254.169.254/latest/meta-data/", "http://localhost/", "file:///etc/passwd"} {
		refused = append(refused, serve(mux, kform(url.Values{"action": {"add_page"}, "account": {"1"}, "url": {u}})).Code)
	}

	// Assert
	if added.Code != http.StatusSeeOther || !strings.Contains(added.Header().Get("Location"), "outcome=added") {
		t.Fatalf("add: %d %q", added.Code, added.Header().Get("Location"))
	}
	if len(ms.docs) != 1 || ms.docs[0].SourceKey != websync.Key("https://www.johnstockeraistudio.com/legal/refund") || ms.docs[0].Title != "Refund policy" {
		t.Fatalf("docs = %+v", ms.docs)
	}
	if again.Code != http.StatusUnprocessableEntity || !strings.Contains(again.Body.String(), "already in the list") {
		t.Fatalf("duplicate: %d", again.Code)
	}
	for _, c := range refused {
		if c != http.StatusUnprocessableEntity {
			t.Fatalf("internal address codes = %v", refused)
		}
	}
	if len(mw.srcs) != 1 {
		t.Fatalf("sources = %d, want only the public page", len(mw.srcs))
	}
}

func TestWeb_RemoveDeletesDocumentAndStaysInAccount(t *testing.T) {
	// Arrange
	mux, ms, mw := webEnv(t)
	serve(mux, kform(url.Values{"action": {"add_page"}, "account": {"1"}, "url": {"https://example.com/price"}}))
	id := mw.srcs[0].ID

	// Act
	cross := serve(mux, kform(url.Values{"action": {"remove_page"}, "account": {"2"}, "id": {"1"}}))
	removed := serve(mux, kform(url.Values{"action": {"remove_page"}, "account": {"1"}, "id": {strconvI(id)}}))
	page := httptest.NewRequest(http.MethodGet, "/admin/knowledge?account=1", nil)
	page.SetBasicAuth(Username, pw)
	body := serve(mux, page).Body.String()

	// Assert
	if cross.Code != http.StatusUnprocessableEntity || removed.Code != http.StatusSeeOther {
		t.Fatalf("cross=%d removed=%d", cross.Code, removed.Code)
	}
	if len(ms.deleted) != 1 || ms.deleted[0] != ms.docs[0].ID || len(mw.srcs) != 0 || !strings.Contains(body, "Website pages") {
		t.Fatalf("deleted=%v srcs=%d", ms.deleted, len(mw.srcs))
	}
}

func strconvI(i int64) string { return strconv.FormatInt(i, 10) }

func TestWeb_ScheduleAndSyncAll(t *testing.T) {
	// Arrange
	mux, _, mw := webEnv(t)
	serve(mux, kform(url.Values{"action": {"add_page"}, "account": {"1"}, "url": {"https://example.com/price"}}))

	// Act
	weekly := serve(mux, kform(url.Values{"action": {"page_interval"}, "account": {"1"}, "id": {"1"}, "interval": {"168"}}))
	odd := serve(mux, kform(url.Values{"action": {"page_interval"}, "account": {"1"}, "id": {"1"}, "interval": {"5"}}))
	all := serve(mux, kform(url.Values{"action": {"sync_all"}, "account": {"1"}}))

	// Assert
	if weekly.Code != http.StatusSeeOther || mw.srcs[0].IntervalHours != 168 {
		t.Fatalf("weekly: %d %+v", weekly.Code, mw.srcs)
	}
	if odd.Code != http.StatusUnprocessableEntity || mw.srcs[0].IntervalHours != 168 {
		t.Fatalf("odd interval accepted: %d", odd.Code)
	}
	if all.Code != http.StatusSeeOther || !strings.Contains(all.Header().Get("Location"), "count=1") {
		t.Fatalf("sync all: %d %q", all.Code, all.Header().Get("Location"))
	}
}

func TestWeb_FeedAddedReadInBackgroundAndRemovedWithItsRows(t *testing.T) {
	// Arrange
	mux, ms, mw := webEnv(t)
	sheet := "https://docs.google.com/spreadsheets/d/e/abc/pub?output=csv"

	// Act
	added := serve(mux, kform(url.Values{"action": {"add_page"}, "account": {"1"}, "kind": {"feed"}, "url": {sheet}}))
	page := httptest.NewRequest(http.MethodGet, "/admin/knowledge?account=1&done=feed_started", nil)
	page.SetBasicAuth(Username, pw)
	body := serve(mux, page).Body.String()
	docsAfterAdd := len(ms.docs)
	removed := serve(mux, kform(url.Values{"action": {"remove_page"}, "account": {"1"}, "id": {strconvI(mw.srcs[0].ID)}}))

	// Assert
	if added.Code != http.StatusSeeOther || !strings.Contains(added.Header().Get("Location"), "done=feed_started") {
		t.Fatalf("add: %d %q", added.Code, added.Header().Get("Location"))
	}
	if docsAfterAdd != 2 || ms.docs[0].SourceKey != websync.FeedKey(1, "faq-1") || ms.docs[0].Kind != knowledge.KindFAQ {
		t.Fatalf("docs = %+v", ms.docs)
	}
	for _, want := range []string{"Reading the file in the background", "Data file", "2 rows", "delete its 2 answers"} {
		if !strings.Contains(body, want) {
			t.Errorf("page missing %q", want)
		}
	}
	if removed.Code != http.StatusSeeOther || len(ms.deleted) != 2 || len(mw.srcs) != 0 {
		t.Errorf("remove: %d deleted=%v srcs=%d", removed.Code, ms.deleted, len(mw.srcs))
	}
}

func TestWeb_GoogleEditLinksBecomeDownloads(t *testing.T) {
	// Arrange
	mux, _, mw := webEnv(t)
	sheet := "https://docs.google.com/spreadsheets/d/1AbC_d-9/edit?gid=42#gid=42"
	doc := "https://docs.google.com/document/d/1XyZ-0_q/edit?tab=t.0"

	// Act: the owner picked "page" for the sheet and "data file" for the doc.
	serve(mux, kform(url.Values{"action": {"add_page"}, "account": {"1"}, "kind": {websync.KindPage}, "url": {sheet}}))
	serve(mux, kform(url.Values{"action": {"add_page"}, "account": {"1"}, "kind": {websync.KindFeed}, "url": {doc}}))

	// Assert: the link decides; a sheet is a data file, a doc is a page.
	if len(mw.srcs) != 2 {
		t.Fatalf("sources = %+v", mw.srcs)
	}
	if s := mw.srcs[0]; s.URL != "https://docs.google.com/spreadsheets/d/1AbC_d-9/export?format=csv&gid=42" || s.Kind != websync.KindFeed {
		t.Errorf("sheet stored as %q kind %q", s.URL, s.Kind)
	}
	if s := mw.srcs[1]; s.URL != "https://docs.google.com/document/d/1XyZ-0_q/export?format=txt" || s.Kind != websync.KindPage {
		t.Errorf("doc stored as %q kind %q", s.URL, s.Kind)
	}
}
