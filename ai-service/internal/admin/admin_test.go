package admin

import (
	"context"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"net/url"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/llm"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/settings"
)

const pw = "correct-horse"

type env struct {
	mux    *http.ServeMux
	store  *settings.Store
	sw     *llm.Switch
	h      *Handler
	probed []settings.Provider
}

func setup(t *testing.T, probeErr error) *env {
	t.Helper()
	store, err := settings.Open(filepath.Join(t.TempDir(), "s.json"), settings.LLM{
		Primary: settings.Provider{BaseURL: "https://openrouter.ai/api/v1", APIKey: "sk-or-secret-9876", Model: "a/model"},
	})
	if err != nil {
		t.Fatal(err)
	}
	e := &env{mux: http.NewServeMux(), store: store, sw: &llm.Switch{}}
	h := &Handler{
		Password: pw, Store: store, Switch: e.sw, Timeout: time.Second,
		Logger: slog.New(slog.NewJSONHandler(io.Discard, nil)),
		Probe: func(_ context.Context, p settings.Provider) (llm.Result, error) {
			e.probed = append(e.probed, p)
			return llm.Result{Model: p.Model}, probeErr
		},
	}
	e.h = h
	h.Routes(e.mux)
	return e
}

func (e *env) do(r *http.Request) *httptest.ResponseRecorder {
	rec := httptest.NewRecorder()
	e.mux.ServeHTTP(rec, r)
	return rec
}

func get(auth bool) *http.Request {
	r := httptest.NewRequest(http.MethodGet, "/admin/providers", nil)
	if auth {
		r.SetBasicAuth(Username, pw)
	}
	return r
}

func post(form url.Values) *http.Request {
	r := httptest.NewRequest(http.MethodPost, "/admin/providers", strings.NewReader(form.Encode()))
	r.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	r.Header.Set("Sec-Fetch-Site", "same-origin")
	r.SetBasicAuth(Username, pw)
	return r
}

func baseForm() url.Values {
	return url.Values{
		"primary_base_url": {"https://openrouter.ai/api/v1"},
		"primary_api_key":  {""},
		"primary_model":    {"a/model"},
	}
}

func TestAuth_RequiredAndChecked(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	wrong := get(false)
	wrong.SetBasicAuth(Username, "nope")

	// Act
	none, bad, good := e.do(get(false)), e.do(wrong), e.do(get(true))

	// Assert
	if none.Code != 401 || bad.Code != 401 || good.Code != 200 {
		t.Errorf("codes none=%d bad=%d good=%d", none.Code, bad.Code, good.Code)
	}
	if !strings.Contains(none.Header().Get("WWW-Authenticate"), "Basic") {
		t.Error("missing WWW-Authenticate challenge")
	}
}

func TestShow_MasksKeyAndSetsSecurityHeaders(t *testing.T) {
	// Arrange
	e := setup(t, nil)

	// Act
	rec := e.do(get(true))

	// Assert
	body := rec.Body.String()
	if strings.Contains(body, "sk-or-secret-9876") {
		t.Fatal("full API key rendered in page")
	}
	if !strings.Contains(body, "••••9876") || !strings.Contains(body, "a/model") {
		t.Error("expected masked key and model in page")
	}
	if rec.Header().Get("Cache-Control") != "no-store" || rec.Header().Get("Content-Security-Policy") == "" {
		t.Errorf("headers = %v", rec.Header())
	}
}

func TestSave_BlankKeyKeepsSavedKeyAndSwitchesLive(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	form := baseForm()
	form.Set("primary_model", "b/model")
	form.Set("fallback_base_url", "https://api.openai.com/v1")
	form.Set("fallback_api_key", "sk-openai-1111")
	form.Set("fallback_model", "c-model")

	// Act
	rec := e.do(post(form))

	// Assert
	if rec.Code != http.StatusSeeOther || rec.Header().Get("Location") != "/admin/providers?saved=1" {
		t.Fatalf("code=%d location=%q body=%s", rec.Code, rec.Header().Get("Location"), rec.Body)
	}
	got := e.store.Get()
	if got.Primary.APIKey != "sk-or-secret-9876" || got.Primary.Model != "b/model" || got.Fallback.APIKey != "sk-openai-1111" {
		t.Errorf("stored = %+v", got)
	}
	if _, err := e.sw.Complete(context.Background(), nil); errors.Is(err, llm.ErrNotConfigured) {
		t.Error("switch was not updated after save")
	}
}

func TestSave_ClearingFallbackRemovesIt(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	_ = e.store.Save(settings.LLM{
		Primary:  e.store.Get().Primary,
		Fallback: settings.Provider{BaseURL: "https://api.openai.com/v1", APIKey: "k", Model: "m"},
	})
	form := baseForm() // fallback fields absent/blank

	// Act
	rec := e.do(post(form))

	// Assert
	if rec.Code != http.StatusSeeOther || e.store.Get().Fallback.Configured() {
		t.Errorf("code=%d fallback=%+v", rec.Code, e.store.Get().Fallback)
	}
}

func TestSave_InvalidReturns422AndKeepsSettings(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	form := baseForm()
	form.Set("primary_base_url", "not a url")

	// Act
	rec := e.do(post(form))

	// Assert
	if rec.Code != http.StatusUnprocessableEntity || !strings.Contains(rec.Body.String(), "Not saved") {
		t.Errorf("code=%d", rec.Code)
	}
	if e.store.Get().Primary.BaseURL != "https://openrouter.ai/api/v1" {
		t.Error("invalid input changed stored settings")
	}
}

func TestSave_RejectsCrossOriginPost(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	r := post(baseForm())
	r.Header.Set("Sec-Fetch-Site", "cross-site")

	// Act
	rec := e.do(r)

	// Assert
	if rec.Code != http.StatusForbidden {
		t.Errorf("code=%d, want 403", rec.Code)
	}
}

func TestTest_ProbesUnsavedValuesWithoutSaving(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	form := baseForm()
	form.Set("primary_model", "unsaved/model")
	form.Set("test", "primary")

	// Act
	rec := e.do(post(form))

	// Assert
	if rec.Code != 200 || !strings.Contains(rec.Body.String(), "Connected") {
		t.Fatalf("code=%d body=%s", rec.Code, rec.Body)
	}
	if len(e.probed) != 1 || e.probed[0].Model != "unsaved/model" || e.probed[0].APIKey != "sk-or-secret-9876" {
		t.Errorf("probed = %+v", e.probed)
	}
	if e.store.Get().Primary.Model != "a/model" {
		t.Error("test button must not save")
	}
}

func TestTest_ShowsProviderError(t *testing.T) {
	// Arrange
	e := setup(t, errors.New("llm status 401: invalid key"))
	form := baseForm()
	form.Set("test", "primary")

	// Act
	rec := e.do(post(form))

	// Assert
	if !strings.Contains(rec.Body.String(), "Test failed") || !strings.Contains(rec.Body.String(), "invalid key") {
		t.Errorf("body = %s", rec.Body)
	}
}

func TestTest_EmptyFallbackAsksToFillIn(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	form := baseForm()
	form.Set("test", "fallback")

	// Act
	rec := e.do(post(form))

	// Assert
	if len(e.probed) != 0 || !strings.Contains(rec.Body.String(), "Fill in base URL") {
		t.Errorf("probed=%d body=%s", len(e.probed), rec.Body)
	}
}

func TestSavedKeyIsNotSentToANewBaseURL(t *testing.T) {
	// Arrange: same blank key field, but the base URL now points elsewhere.
	e := setup(t, nil)
	testForm := baseForm()
	testForm.Set("primary_base_url", "https://attacker.example/v1")
	testForm.Set("test", "primary")
	saveForm := baseForm()
	saveForm.Set("primary_base_url", "https://attacker.example/v1")

	// Act
	testRec := e.do(post(testForm))
	saveRec := e.do(post(saveForm))

	// Assert
	if len(e.probed) != 0 || !strings.Contains(testRec.Body.String(), "Fill in base URL") {
		t.Errorf("saved key was probed against a new host: %+v", e.probed)
	}
	if saveRec.Code != http.StatusUnprocessableEntity || !strings.Contains(saveRec.Body.String(), "API key is required") {
		t.Errorf("save code=%d", saveRec.Code)
	}
	if e.store.Get().Primary.BaseURL != "https://openrouter.ai/api/v1" {
		t.Error("settings changed")
	}
}

func TestSavedKeyKeptWhenOnlyTrailingSlashDiffers(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	form := baseForm()
	form.Set("primary_base_url", "https://openrouter.ai/api/v1/")

	// Act
	rec := e.do(post(form))

	// Assert
	if rec.Code != http.StatusSeeOther || e.store.Get().Primary.APIKey != "sk-or-secret-9876" {
		t.Errorf("code=%d key kept=%v", rec.Code, e.store.Get().Primary.APIKey == "sk-or-secret-9876")
	}
}

func TestSave_FallbackOnSameURLReusesPrimaryKey(t *testing.T) {
	// Arrange: same OpenRouter account, backup model, no second key.
	e := setup(t, nil)
	form := baseForm()
	form.Set("fallback_base_url", "https://openrouter.ai/api/v1/")
	form.Set("fallback_model", "backup/model")

	// Act
	rec := e.do(post(form))

	// Assert
	if rec.Code != http.StatusSeeOther || rec.Header().Get("Location") != "/admin/providers?saved=1" {
		t.Fatalf("code=%d location=%q", rec.Code, rec.Header().Get("Location"))
	}
	if fb := e.store.Get().Fallback; fb.APIKey != "sk-or-secret-9876" || fb.Model != "backup/model" {
		t.Errorf("fallback = %+v", fb)
	}
}

func TestSave_IncompleteFallbackIsTurnedOffNotBlocking(t *testing.T) {
	// Arrange: different provider, key left blank.
	e := setup(t, nil)
	form := baseForm()
	form.Set("primary_model", "new/model")
	form.Set("fallback_base_url", "https://api.openai.com/v1")
	form.Set("fallback_model", "gpt-x")

	// Act
	rec := e.do(post(form))
	page := e.do(get(true))
	notice := e.do(func() *http.Request { r := get(true); r.URL.RawQuery = "saved=1&fallback=off"; return r }())

	// Assert
	if rec.Code != http.StatusSeeOther || rec.Header().Get("Location") != "/admin/providers?saved=1&fallback=off" {
		t.Fatalf("code=%d location=%q body=%s", rec.Code, rec.Header().Get("Location"), rec.Body)
	}
	got := e.store.Get()
	if got.Primary.Model != "new/model" || got.Fallback != (settings.Provider{}) {
		t.Errorf("stored = %+v", got)
	}
	if page.Code != 200 || !strings.Contains(notice.Body.String(), "Fallback provider is off") {
		t.Errorf("notice missing: %s", notice.Body)
	}
}

func TestTest_FallbackOnSameURLUsesPrimaryKey(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	form := baseForm()
	form.Set("fallback_base_url", "https://openrouter.ai/api/v1")
	form.Set("fallback_model", "backup/model")
	form.Set("test", "fallback")

	// Act
	e.do(post(form))

	// Assert
	if len(e.probed) != 1 || e.probed[0].APIKey != "sk-or-secret-9876" || e.probed[0].Model != "backup/model" {
		t.Errorf("probed = %+v", e.probed)
	}
}

func TestTestThenSave_KeepsTheNewlyTypedKey(t *testing.T) {
	// Arrange: admin types a new key and clicks Test first.
	e := setup(t, nil)
	testForm := baseForm()
	testForm.Set("primary_api_key", "sk-new-typed-key-5555")
	testForm.Set("test", "primary")

	// Act: Test, then submit the re-rendered form as the browser would.
	testRec := e.do(post(testForm))
	body := testRec.Body.String()

	// Assert: the typed key is refilled so the next Save sends it,
	// and the placeholder still describes the saved key, not the typed one.
	if !strings.Contains(body, `value="sk-new-typed-key-5555"`) {
		t.Fatalf("typed key not refilled after Test")
	}
	if strings.Contains(body, "Saved key ••••5555") || !strings.Contains(body, "Saved key ••••9876") {
		t.Errorf("placeholder must describe the saved key only")
	}
	if strings.Contains(body, "sk-or-secret-9876") {
		t.Error("saved key leaked into page")
	}

	saveForm := baseForm()
	saveForm.Set("primary_api_key", "sk-new-typed-key-5555")
	if rec := e.do(post(saveForm)); rec.Code != http.StatusSeeOther {
		t.Fatalf("save code=%d", rec.Code)
	}
	if got := e.store.Get().Primary.APIKey; got != "sk-new-typed-key-5555" {
		t.Errorf("stored key = %q", got)
	}
}

func TestShow_NeverPrefillsSavedKey(t *testing.T) {
	// Arrange
	e := setup(t, nil)

	// Act
	body := e.do(get(true)).Body.String()

	// Assert: key inputs render empty; only the mask appears.
	if strings.Contains(body, "sk-or-secret-9876") || !strings.Contains(body, `value="" placeholder="Saved key ••••9876"`) {
		t.Error("saved key must never be prefilled; placeholder should show its mask")
	}
}

func TestSave_UpdatesTheRewriteModelLive(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	rw := &llm.Switch{}
	e.h.Rewrite, e.h.RewriteModel = rw, "small-model"
	form := baseForm()

	// Act
	w := e.do(post(form))

	// Assert
	if w.Code != http.StatusSeeOther {
		t.Fatalf("save = %d", w.Code)
	}
	if _, err := rw.Complete(context.Background(), nil); errors.Is(err, llm.ErrNotConfigured) {
		t.Error("saving provider settings must also point the rewrite switch at the new settings")
	}
}
