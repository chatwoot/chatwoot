package admin

import (
	"bytes"
	"context"
	"io"
	"log/slog"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/embed"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/llm"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/settings"
)

type memStore struct {
	docs    []knowledge.Document
	deleted []int64
	hits    []knowledge.Hit
	query   knowledge.Query
}

func (m *memStore) Insert(_ context.Context, d knowledge.Document, _ string, chunks []knowledge.Chunk) (int64, error) {
	d.ID, d.Chunks = int64(len(m.docs)+1), len(chunks)
	m.docs = append(m.docs, d)
	return d.ID, nil
}
func (m *memStore) ReplaceChunks(context.Context, knowledge.Document, string, []knowledge.Chunk) error {
	return nil
}
func (m *memStore) List(_ context.Context, acct int64, _ string) ([]knowledge.Document, error) {
	var out []knowledge.Document
	for _, d := range m.docs {
		if d.AccountID == acct {
			out = append(out, d)
		}
	}
	return out, nil
}
func (m *memStore) Delete(_ context.Context, acct, id int64) error {
	m.deleted = append(m.deleted, id)
	return nil
}
func (m *memStore) Search(_ context.Context, q knowledge.Query) ([]knowledge.Hit, error) {
	m.query = q
	return m.hits, nil
}
func (m *memStore) Get(_ context.Context, acct, id int64) (knowledge.Document, error) {
	for _, d := range m.docs {
		if d.ID == id && d.AccountID == acct {
			return d, nil
		}
	}
	return knowledge.Document{}, knowledge.ErrNotFound
}
func (m *memStore) Update(_ context.Context, d knowledge.Document, _ string, chunks []knowledge.Chunk) error {
	for i, cur := range m.docs {
		if cur.ID == d.ID && cur.AccountID == d.AccountID {
			d.Chunks, d.UseCount = len(chunks), cur.UseCount
			m.docs[i] = d
			return nil
		}
	}
	return knowledge.ErrNotFound
}
func (m *memStore) MarkUsed(context.Context, int64, []int64) error { return nil }
func (m *memStore) GetByKey(_ context.Context, acct int64, key string) (knowledge.Document, error) {
	for _, d := range m.docs {
		if d.AccountID == acct && key != "" && d.SourceKey == key {
			return d, nil
		}
	}
	return knowledge.Document{}, knowledge.ErrNotFound
}

type constEmbedder struct{ model string }

func (c constEmbedder) Model() string { return c.model }
func (c constEmbedder) Embed(_ context.Context, texts []string) ([][]float32, error) {
	return make([][]float32, len(texts)), nil
}

func knowledgeEnv(t *testing.T, withDB bool) (*http.ServeMux, *memStore) {
	t.Helper()
	store, err := settings.Open(t.TempDir()+"/s.json", settings.LLM{})
	if err != nil {
		t.Fatal(err)
	}
	ms := &memStore{}
	bkk, _ := time.LoadLocation("Asia/Bangkok")
	h := &Handler{Password: pw, Store: store, Switch: &llm.Switch{}, Timeout: time.Second, Location: bkk,
		Logger: slog.New(slog.NewJSONHandler(io.Discard, nil))}
	if withDB {
		h.Knowledge = &knowledge.Service{Store: ms, Embedder: constEmbedder{"m1"}, TopK: 4, ChunkRunes: 800}
	}
	mux := http.NewServeMux()
	h.Routes(mux)
	return mux, ms
}

func kpost(body io.Reader, contentType string) *http.Request {
	r := httptest.NewRequest(http.MethodPost, "/admin/knowledge", body)
	r.Header.Set("Content-Type", contentType)
	r.Header.Set("Sec-Fetch-Site", "same-origin")
	r.SetBasicAuth(Username, pw)
	return r
}

func kform(v url.Values) *http.Request {
	return kpost(strings.NewReader(v.Encode()), "application/x-www-form-urlencoded")
}

func serve(mux *http.ServeMux, r *http.Request) *httptest.ResponseRecorder {
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, r)
	return rec
}

func TestKnowledge_AddFAQThenListed(t *testing.T) {
	// Arrange
	mux, ms := knowledgeEnv(t, true)
	form := url.Values{"action": {"add_faq"}, "account": {"2"}, "inbox": {"5"},
		"question": {"ร้านเปิดกี่โมง"}, "answer": {"9:00–18:00"}}

	// Act
	rec := serve(mux, kform(form))
	list := httptest.NewRequest(http.MethodGet, "/admin/knowledge?account=2", nil)
	list.SetBasicAuth(Username, pw)
	page := serve(mux, list)

	// Assert
	if rec.Code != http.StatusSeeOther || rec.Header().Get("Location") != "/admin/knowledge?account=2&done=added&chunks=1" {
		t.Fatalf("code=%d loc=%q body=%s", rec.Code, rec.Header().Get("Location"), rec.Body)
	}
	if len(ms.docs) != 1 || ms.docs[0].Kind != knowledge.KindFAQ || ms.docs[0].InboxID != 5 || ms.docs[0].AccountID != 2 {
		t.Errorf("stored = %+v", ms.docs)
	}
	if !strings.Contains(page.Body.String(), "ร้านเปิดกี่โมง") || !strings.Contains(page.Body.String(), "Inbox 5") {
		t.Error("document not listed")
	}
}

func TestDocView_PreviewDropsHeadingMarkers(t *testing.T) {
	// Arrange
	d := knowledge.Document{Kind: knowledge.KindText, Title: "D", Content: "# Delivery\n\n## Fees\nFree over 300 baht #1"}

	// Act
	v := (&Handler{}).toDocView(d, time.Now())

	// Assert
	if v.Preview != "Delivery Fees Free over 300 baht #1" {
		t.Errorf("preview = %q", v.Preview)
	}
}

func TestKnowledge_InvalidAddKeepsValues(t *testing.T) {
	// Arrange
	mux, ms := knowledgeEnv(t, true)
	form := url.Values{"action": {"add_faq"}, "account": {"1"}, "question": {"Only a question"}, "answer": {""}}

	// Act
	rec := serve(mux, kform(form))

	// Assert
	if rec.Code != http.StatusUnprocessableEntity || len(ms.docs) != 0 {
		t.Fatalf("code=%d docs=%d", rec.Code, len(ms.docs))
	}
	body := rec.Body.String()
	if !strings.Contains(body, "content is required") || !strings.Contains(body, `value="Only a question"`) {
		t.Errorf("body missing error or kept value")
	}
}

func upload(t *testing.T, filename, content string) *http.Request {
	t.Helper()
	var buf bytes.Buffer
	mw := multipart.NewWriter(&buf)
	_ = mw.WriteField("action", "add_doc")
	_ = mw.WriteField("account", "1")
	fw, _ := mw.CreateFormFile("file", filename)
	_, _ = fw.Write([]byte(content))
	_ = mw.Close()
	return kpost(&buf, mw.FormDataContentType())
}

func TestKnowledge_UploadTitleFromHeadingElseFileName(t *testing.T) {
	// Arrange
	mux, ms := knowledgeEnv(t, true)

	// Act
	rec := serve(mux, upload(t, "shipping-policy.md", "\xef\xbb\xbf# Shipping\n\nส่งฟรีเมื่อซื้อครบ 500 บาท"))
	plain := serve(mux, upload(t, "opening-hours.txt", "เปิด 8 โมง"))

	// Assert
	if rec.Code != http.StatusSeeOther || plain.Code != http.StatusSeeOther || len(ms.docs) != 2 {
		t.Fatalf("code=%d/%d body=%s", rec.Code, plain.Code, rec.Body)
	}
	if ms.docs[0].Title != "Shipping" || !strings.HasPrefix(ms.docs[0].Content, "# Shipping") || ms.docs[1].Title != "opening-hours" {
		t.Errorf("docs = %+v", ms.docs)
	}
}

func TestKnowledge_RejectsUnsupportedOrBinaryFiles(t *testing.T) {
	cases := map[string]struct{ name, content, want string }{
		"pdf":      {"price.pdf", "%PDF-1.7", "not supported yet"},
		"not utf8": {"notes.txt", "\xff\xfe\x00", "not UTF-8"},
	}
	for name, tc := range cases {
		t.Run(name, func(t *testing.T) {
			// Arrange
			mux, ms := knowledgeEnv(t, true)

			// Act
			rec := serve(mux, upload(t, tc.name, tc.content))

			// Assert
			if rec.Code != http.StatusUnprocessableEntity || len(ms.docs) != 0 || !strings.Contains(rec.Body.String(), tc.want) {
				t.Errorf("code=%d docs=%d", rec.Code, len(ms.docs))
			}
		})
	}
}

func TestKnowledge_DeleteIsAccountScoped(t *testing.T) {
	// Arrange
	mux, ms := knowledgeEnv(t, true)

	// Act
	rec := serve(mux, kform(url.Values{"action": {"delete"}, "account": {"3"}, "id": {"9"}}))

	// Assert
	if rec.Code != http.StatusSeeOther || rec.Header().Get("Location") != "/admin/knowledge?account=3&done=deleted" || len(ms.deleted) != 1 {
		t.Errorf("code=%d loc=%q deleted=%v", rec.Code, rec.Header().Get("Location"), ms.deleted)
	}
}

func TestKnowledge_DisabledWithoutDatabase(t *testing.T) {
	// Arrange
	mux, _ := knowledgeEnv(t, false)
	get := httptest.NewRequest(http.MethodGet, "/admin/knowledge", nil)
	get.SetBasicAuth(Username, pw)

	// Act
	page := serve(mux, get)
	add := serve(mux, kform(url.Values{"action": {"add_faq"}}))

	// Assert
	if page.Code != 200 || !strings.Contains(page.Body.String(), "DATABASE_URL") || add.Code != http.StatusServiceUnavailable {
		t.Errorf("page=%d add=%d", page.Code, add.Code)
	}
}

func TestKnowledge_CrossOriginAndAuth(t *testing.T) {
	// Arrange
	mux, ms := knowledgeEnv(t, true)
	cross := kform(url.Values{"action": {"delete"}, "id": {"1"}})
	cross.Header.Set("Sec-Fetch-Site", "cross-site")
	noAuth := httptest.NewRequest(http.MethodGet, "/admin/knowledge", nil)

	// Act
	c, a := serve(mux, cross), serve(mux, noAuth)

	// Assert
	if c.Code != http.StatusForbidden || a.Code != http.StatusUnauthorized || len(ms.deleted) != 0 {
		t.Errorf("cross=%d noauth=%d deleted=%v", c.Code, a.Code, ms.deleted)
	}
}

func TestSave_EmbeddingReusesPrimaryKeyAndSwitchesLive(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	sw := &embed.Switch{}
	h := &Handler{Password: pw, Store: e.store, Switch: e.sw, Embedder: sw, Timeout: time.Second,
		Logger: slog.New(slog.NewJSONHandler(io.Discard, nil))}
	mux := http.NewServeMux()
	h.Routes(mux)
	form := baseForm()
	form.Set("embedding_base_url", "https://openrouter.ai/api/v1/")
	form.Set("embedding_model", "text-embedding-3-small")

	// Act
	rec := serve(mux, post(form))

	// Assert
	if rec.Code != http.StatusSeeOther || rec.Header().Get("Location") != "/admin/providers?saved=1" {
		t.Fatalf("code=%d loc=%q body=%s", rec.Code, rec.Header().Get("Location"), rec.Body)
	}
	if got := e.store.Get().Embedding; got.APIKey != "sk-or-secret-9876" || got.Model != "text-embedding-3-small" {
		t.Errorf("embedding = %+v", got)
	}
	if sw.Model() != "text-embedding-3-small" {
		t.Errorf("embed switch model = %q", sw.Model())
	}
}

func TestSave_IncompleteEmbeddingTurnedOff(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	form := baseForm()
	form.Set("embedding_base_url", "https://api.openai.com/v1")
	form.Set("embedding_model", "text-embedding-3-small")

	// Act
	rec := e.do(post(form))

	// Assert
	if rec.Header().Get("Location") != "/admin/providers?saved=1&embedding=off" || e.store.Get().Embedding != (settings.Provider{}) {
		t.Errorf("loc=%q embedding=%+v", rec.Header().Get("Location"), e.store.Get().Embedding)
	}
}

func TestTest_EmbeddingSlotUsesEmbeddingProbe(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	var probed settings.Provider
	h := &Handler{Password: pw, Store: e.store, Switch: e.sw, Timeout: time.Second,
		Logger:         slog.New(slog.NewJSONHandler(io.Discard, nil)),
		ProbeEmbedding: func(_ context.Context, p settings.Provider) error { probed = p; return nil }}
	mux := http.NewServeMux()
	h.Routes(mux)
	form := baseForm()
	form.Set("embedding_base_url", "https://openrouter.ai/api/v1")
	form.Set("embedding_model", "text-embedding-3-small")
	form.Set("test", "embedding")

	// Act
	rec := serve(mux, post(form))

	// Assert
	if probed.Model != "text-embedding-3-small" || probed.APIKey != "sk-or-secret-9876" {
		t.Errorf("probed = %+v", probed)
	}
	if !strings.Contains(rec.Body.String(), "1536-dimension vector") {
		t.Error("success message missing")
	}
}

func (m *memStore) ListByKeyPrefix(_ context.Context, acct int64, prefix string) ([]knowledge.Document, error) {
	var out []knowledge.Document
	for _, d := range m.docs {
		if (d.AccountID == acct || d.AccountID == 0) && d.SourceKey != "" && strings.HasPrefix(d.SourceKey, prefix) {
			out = append(out, d)
		}
	}
	return out, nil
}
