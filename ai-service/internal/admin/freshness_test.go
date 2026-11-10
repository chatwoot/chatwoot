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

func kget(mux *http.ServeMux, path string) string {
	r := httptest.NewRequest(http.MethodGet, path, nil)
	r.SetBasicAuth(Username, pw)
	return serve(mux, r).Body.String()
}

func TestKnowledge_DatesStoredInBusinessTimeZone(t *testing.T) {
	// Arrange
	mux, ms := knowledgeEnv(t, true)
	form := url.Values{"action": {"add_faq"}, "account": {"1"}, "question": {"โปรปีใหม่"}, "answer": {"ลด 20%"},
		"valid_from": {"2026-12-25"}, "valid_until": {"2026-12-31"}}

	// Act
	rec := serve(mux, kform(form))

	// Assert
	bkk, _ := time.LoadLocation("Asia/Bangkok")
	if rec.Code != http.StatusSeeOther || len(ms.docs) != 1 {
		t.Fatalf("code=%d docs=%d body=%s", rec.Code, len(ms.docs), rec.Body)
	}
	d := ms.docs[0]
	if !d.ValidFrom.Equal(time.Date(2026, 12, 25, 0, 0, 0, 0, bkk)) || !d.ValidUntil.Equal(time.Date(2027, 1, 1, 0, 0, 0, 0, bkk)) {
		t.Errorf("window = %v – %v, want 25 Dec 00:00 to 1 Jan 00:00 Bangkok (last day inclusive)", d.ValidFrom, d.ValidUntil)
	}
}

func TestKnowledge_BadDatesRejectedAndNothingStored(t *testing.T) {
	cases := map[string]url.Values{
		"not a date":       {"valid_until": {"31/12/2026"}},
		"end before start": {"valid_from": {"2026-12-31"}, "valid_until": {"2026-12-01"}},
	}
	for name, extra := range cases {
		t.Run(name, func(t *testing.T) {
			// Arrange
			mux, ms := knowledgeEnv(t, true)
			form := url.Values{"action": {"add_faq"}, "account": {"1"}, "question": {"q"}, "answer": {"a"}}
			for k, v := range extra {
				form[k] = v
			}

			// Act
			rec := serve(mux, kform(form))

			// Assert
			if rec.Code != http.StatusUnprocessableEntity || len(ms.docs) != 0 {
				t.Fatalf("code=%d docs=%d", rec.Code, len(ms.docs))
			}
		})
	}
}

func TestKnowledge_DuplicateWarnsThenAddAnyway(t *testing.T) {
	// Arrange
	mux, ms := knowledgeEnv(t, true)
	ms.docs = []knowledge.Document{{ID: 1, AccountID: 1, Kind: knowledge.KindFAQ, Title: "ราคาคอร์ส", Content: "3,900"}}
	ms.hits = []knowledge.Hit{{ChunkID: 1, DocumentID: 1, Title: "ราคาคอร์ส", Score: 0.93}}
	form := url.Values{"action": {"add_faq"}, "account": {"1"}, "question": {"คอร์สราคาเท่าไหร่"}, "answer": {"3,900 บาท"}}

	// Act
	warn := serve(mux, kform(form))
	form.Set("confirm_duplicate", "1")
	added := serve(mux, kform(form))

	// Assert
	body := warn.Body.String()
	if warn.Code != http.StatusOK || !strings.Contains(body, "already have") || !strings.Contains(body, "93% similar") ||
		!strings.Contains(body, "edit=1") || !strings.Contains(body, `name="question" value="คอร์สราคาเท่าไหร่"`) {
		t.Fatalf("no duplicate warning: code=%d", warn.Code)
	}
	if !ms.query.IncludeInactive {
		t.Error("duplicate check must include expired and scheduled documents")
	}
	if added.Code != http.StatusSeeOther || len(ms.docs) != 2 {
		t.Fatalf("add anyway: code=%d docs=%d", added.Code, len(ms.docs))
	}
}

func TestKnowledge_EditInPlace(t *testing.T) {
	// Arrange
	mux, ms := knowledgeEnv(t, true)
	ms.docs = []knowledge.Document{{ID: 3, AccountID: 1, Kind: knowledge.KindFAQ, Title: "ราคา", Content: "9,900", UseCount: 4}}

	// Act
	form := kget(mux, "/admin/knowledge?account=1&edit=3")
	rec := serve(mux, kform(url.Values{"action": {"update"}, "account": {"1"}, "id": {"3"},
		"question": {"ราคา"}, "answer": {"3,900 บาท"}, "valid_until": {"2026-12-31"}}))

	// Assert
	if !strings.Contains(form, "Edit FAQ") || !strings.Contains(form, ">9,900</textarea>") {
		t.Fatal("edit form not filled")
	}
	if rec.Code != http.StatusSeeOther || !strings.Contains(rec.Header().Get("Location"), "done=updated") {
		t.Fatalf("code=%d loc=%q body=%s", rec.Code, rec.Header().Get("Location"), rec.Body)
	}
	if d := ms.docs[0]; d.Content != "3,900 บาท" || d.ValidUntil.IsZero() || d.UseCount != 4 || len(ms.docs) != 1 {
		t.Errorf("after edit = %+v", ms.docs)
	}
}

func TestKnowledge_EditOtherAccountRefused(t *testing.T) {
	// Arrange
	mux, ms := knowledgeEnv(t, true)
	ms.docs = []knowledge.Document{{ID: 3, AccountID: 2, Kind: knowledge.KindFAQ, Title: "secret", Content: "x"}}

	// Act
	page := kget(mux, "/admin/knowledge?account=1&edit=3")
	rec := serve(mux, kform(url.Values{"action": {"update"}, "account": {"1"}, "id": {"3"}, "question": {"q"}, "answer": {"hacked"}}))

	// Assert
	if strings.Contains(page, "secret") || rec.Code != http.StatusUnprocessableEntity || ms.docs[0].Content != "x" {
		t.Fatalf("cross-account edit: code=%d content=%q", rec.Code, ms.docs[0].Content)
	}
}

func TestKnowledge_FiltersAndStatus(t *testing.T) {
	// Arrange
	mux, ms := knowledgeEnv(t, true)
	now := time.Now()
	ms.docs = []knowledge.Document{
		{ID: 1, AccountID: 1, Kind: knowledge.KindFAQ, Title: "Used", Content: "a", UseCount: 3, LastUsedAt: now},
		{ID: 2, AccountID: 1, Kind: knowledge.KindFAQ, Title: "Never", Content: "a"},
		{ID: 3, AccountID: 1, Kind: knowledge.KindFAQ, Title: "Old promo", Content: "a", UseCount: 1, LastUsedAt: now,
			ValidUntil: now.Add(-time.Hour)},
	}

	// Act
	all := kget(mux, "/admin/knowledge?account=1")
	unused := kget(mux, "/admin/knowledge?account=1&show=unused")
	inactive := kget(mux, "/admin/knowledge?account=1&show=inactive")

	// Assert
	if !strings.Contains(all, "3 times, last") || !strings.Contains(all, "Not used yet") || !strings.Contains(all, ">Expired<") {
		t.Error("all: missing usage or status")
	}
	if !strings.Contains(unused, ">Never</h3>") || strings.Contains(unused, ">Used</h3>") {
		t.Error("unused filter wrong")
	}
	if !strings.Contains(inactive, ">Old promo</h3>") || strings.Contains(inactive, ">Never</h3>") {
		t.Error("inactive filter wrong")
	}
}
