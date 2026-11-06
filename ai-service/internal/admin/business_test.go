package admin

import (
	"context"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/llm"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/profile"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/settings"
)

type memProfiles struct {
	saved map[int64]profile.Profile
	saves int
}

func (m *memProfiles) Get(_ context.Context, acct int64) (profile.Profile, error) {
	if p, ok := m.saved[acct]; ok {
		return p, nil
	}
	return profile.Profile{AccountID: acct}, nil
}

func (m *memProfiles) Save(_ context.Context, p profile.Profile) error {
	if err := p.Validate(); err != nil {
		return err
	}
	m.saves++
	m.saved[p.AccountID] = p
	return nil
}

func businessEnv(t *testing.T, withDB bool) (*http.ServeMux, *memProfiles) {
	t.Helper()
	store, err := settings.Open(t.TempDir()+"/s.json", settings.LLM{})
	if err != nil {
		t.Fatal(err)
	}
	mp := &memProfiles{saved: map[int64]profile.Profile{}}
	h := &Handler{Password: pw, Store: store, Switch: &llm.Switch{}, Timeout: time.Second,
		Logger: slog.New(slog.NewJSONHandler(io.Discard, nil))}
	if withDB {
		h.Profiles = mp
	}
	mux := http.NewServeMux()
	h.Routes(mux)
	return mux, mp
}

func bpost(v url.Values) *http.Request {
	r := httptest.NewRequest(http.MethodPost, "/admin/business", strings.NewReader(v.Encode()))
	r.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	r.Header.Set("Sec-Fetch-Site", "same-origin")
	r.SetBasicAuth(Username, pw)
	return r
}

func TestBusiness_SaveThenShow(t *testing.T) {
	// Arrange
	mux, mp := businessEnv(t, true)
	form := url.Values{"account": {"2"}, "business_name": {"  Johnstocker AI Studio "},
		"about": {"คอร์สออนไลน์ AutoCut"}, "tone": {"เป็นกันเอง"}, "contact": {"LINE @johnstocker"}, "rules": {"ห้ามให้ส่วนลด"}}

	// Act
	saved := serve(mux, bpost(form))
	get := httptest.NewRequest(http.MethodGet, "/admin/business?account=2&done=saved", nil)
	get.SetBasicAuth(Username, pw)
	page := serve(mux, get)

	// Assert
	if saved.Code != http.StatusSeeOther || saved.Header().Get("Location") != "/admin/business?account=2&done=saved" {
		t.Fatalf("save = %d %q", saved.Code, saved.Header().Get("Location"))
	}
	if got := mp.saved[2]; got.BusinessName != "Johnstocker AI Studio" || got.Rules != "ห้ามให้ส่วนลด" {
		t.Errorf("saved = %+v (want trimmed values for account 2)", got)
	}
	body := page.Body.String()
	for _, want := range []string{"Johnstocker AI Studio", "คอร์สออนไลน์ AutoCut", "LINE @johnstocker", "Saved"} {
		if !strings.Contains(body, want) {
			t.Errorf("page is missing %q", want)
		}
	}
}

func TestBusiness_InvalidInputSavesNothing(t *testing.T) {
	// Arrange
	mux, mp := businessEnv(t, true)
	form := url.Values{"account": {"1"}, "business_name": {strings.Repeat("ก", profile.MaxNameRunes+1)}, "about": {"kept"}}

	// Act
	w := serve(mux, bpost(form))

	// Assert
	if w.Code != http.StatusUnprocessableEntity {
		t.Fatalf("status = %d, want 422", w.Code)
	}
	if mp.saves != 0 {
		t.Error("an invalid profile was saved")
	}
	if !strings.Contains(w.Body.String(), "kept") {
		t.Error("the form must be re-filled after an error")
	}
}

func TestBusiness_RejectedRequestsChangeNothing(t *testing.T) {
	// Arrange
	mux, mp := businessEnv(t, true)
	form := url.Values{"account": {"1"}, "business_name": {"Evil"}}
	noAuth := bpost(form)
	noAuth.Header.Del("Authorization")
	wrongPw := bpost(form)
	wrongPw.SetBasicAuth(Username, "wrong-password-123")
	crossOrigin := bpost(form)
	crossOrigin.Header.Set("Sec-Fetch-Site", "cross-site")

	// Act
	codes := []int{serve(mux, noAuth).Code, serve(mux, wrongPw).Code, serve(mux, crossOrigin).Code}

	// Assert
	if codes[0] != http.StatusUnauthorized || codes[1] != http.StatusUnauthorized || codes[2] != http.StatusForbidden {
		t.Errorf("codes = %v, want [401 401 403]", codes)
	}
	if mp.saves != 0 || len(mp.saved) != 0 {
		t.Errorf("a rejected request saved a profile: %+v", mp.saved)
	}
}

func TestBusiness_WithoutDatabase(t *testing.T) {
	// Arrange
	mux, _ := businessEnv(t, false)
	get := httptest.NewRequest(http.MethodGet, "/admin/business", nil)
	get.SetBasicAuth(Username, pw)

	// Act
	page := serve(mux, get)
	save := serve(mux, bpost(url.Values{"account": {"1"}, "business_name": {"x"}}))

	// Assert
	if page.Code != http.StatusOK || !strings.Contains(page.Body.String(), "DATABASE_URL") {
		t.Errorf("page = %d, want 200 explaining DATABASE_URL", page.Code)
	}
	if save.Code != http.StatusServiceUnavailable {
		t.Errorf("save = %d, want 503", save.Code)
	}
}

func TestBusiness_MaxLengthThaiFitsTheFormLimit(t *testing.T) {
	// Arrange: urlencoded Thai is 9 bytes per character on the wire.
	mux, mp := businessEnv(t, true)
	field := strings.Repeat("ก", profile.MaxFieldRunes)
	form := url.Values{"account": {"1"}, "business_name": {strings.Repeat("ข", profile.MaxNameRunes)},
		"about": {field}, "tone": {field}, "contact": {field}, "rules": {field}}

	// Act
	w := serve(mux, bpost(form))

	// Assert
	if w.Code != http.StatusSeeOther || mp.saves != 1 {
		t.Fatalf("status = %d, saves = %d; want 303 and one save", w.Code, mp.saves)
	}
}

func TestBusiness_BadAccountIDSavesNothing(t *testing.T) {
	for _, acct := range []string{"0", "-5", "abc", ""} {
		t.Run("account="+acct, func(t *testing.T) {
			// Arrange
			mux, mp := businessEnv(t, true)

			// Act
			w := serve(mux, bpost(url.Values{"account": {acct}, "business_name": {"x"}}))

			// Assert
			if w.Code != http.StatusBadRequest {
				t.Errorf("status = %d, want 400", w.Code)
			}
			if mp.saves != 0 {
				t.Error("a bad account ID saved a profile (it must not fall back to account 1)")
			}
		})
	}
}

func TestBusiness_FeatureSwitchesSaveAndShow(t *testing.T) {
	// Arrange: voice and stickers ticked, images not.
	mux, mp := businessEnv(t, true)
	form := url.Values{"account": {"1"}, "business_name": {"Shop"}, "feature_voice": {"on"}, "feature_stickers": {"on"}}

	// Act
	saved := serve(mux, bpost(form))
	get := httptest.NewRequest(http.MethodGet, "/admin/business?account=1", nil)
	get.SetBasicAuth(Username, pw)
	page := serve(mux, get).Body.String()

	// Assert
	if saved.Code != http.StatusSeeOther {
		t.Fatalf("save = %d", saved.Code)
	}
	if f := mp.saved[1].Features; !f.Voice || f.Images || !f.Stickers {
		t.Errorf("features = %+v, want voice and stickers on, images off", f)
	}
	for _, want := range []string{`name="feature_voice" type="checkbox" checked`, `name="feature_stickers" type="checkbox" checked`} {
		if !strings.Contains(page, want) {
			t.Errorf("page is missing %s", want)
		}
	}
	if strings.Contains(page, `name="feature_images" type="checkbox" checked`) {
		t.Error("images must show unticked")
	}
}

func TestBusiness_UntickingTurnsFeaturesOff(t *testing.T) {
	// Arrange: a profile with every feature on; the form posts no ticks.
	mux, mp := businessEnv(t, true)
	mp.saved[1] = profile.Profile{AccountID: 1, Features: profile.Features{Voice: true, Images: true, Stickers: true}}

	// Act
	serve(mux, bpost(url.Values{"account": {"1"}, "business_name": {"Shop"}}))

	// Assert
	if f := mp.saved[1].Features; f != (profile.Features{}) {
		t.Errorf("features = %+v, want all off when nothing is ticked", f)
	}
}
