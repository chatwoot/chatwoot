// Package admin serves the settings pages: the LLM providers (primary +
// fallback + embeddings), the knowledge base, and each account's business
// profile, all applied without restarting ai-service.
//
// Security: HTTP Basic Auth (RFC 7617) with ADMIN_PASSWORD, constant-time
// compare; cross-origin form posts are rejected (net/http CrossOriginProtection);
// API keys are write-only (only the last 4 characters are ever rendered).
// Serve it over HTTPS outside localhost.
package admin

import (
	"bytes"
	"context"
	"crypto/sha256"
	"crypto/subtle"
	"embed"
	"fmt"
	"html/template"
	"log/slog"
	"net/http"
	"sync"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/audit"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/cfaccess"
	embedclient "github.com/DEV-Johnstocker/chatwoot/ai-service/internal/embed"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/llm"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/mcp"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/oauth"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/profile"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/settings"
)

//go:embed *.html
var pageFS embed.FS

var pages = template.Must(template.New("pages").Funcs(template.FuncMap{
	// dict builds a map so one sub-template can render both provider cards.
	"inc":   func(i int) int { return i + 1 },
	"theme": func() string { return "" }, // replaced per request in renderPage
	"dict": func(kv ...any) map[string]any {
		m := make(map[string]any, len(kv)/2)
		for i := 0; i+1 < len(kv); i += 2 {
			m[kv[i].(string)] = kv[i+1]
		}
		return m
	},
}).ParseFS(pageFS, "*.html"))

// Username for Basic Auth.
const Username = "admin"

// Handler serves /admin.
type Handler struct {
	Password string
	Store    *settings.Store
	Switch   *llm.Switch
	// Rewrite is the query-rewrite completer (RewriteModel on the same
	// provider); refreshed on save like Switch. Nil: no separate rewrite model.
	Rewrite      *llm.Switch
	RewriteModel string
	Embedder     *embedclient.Switch // updated when the embeddings provider is saved
	Timeout      time.Duration       // per provider call
	Logger       *slog.Logger
	// Knowledge enables the knowledge base page; nil when no database is set.
	Knowledge *knowledge.Service
	// Profiles enables the business profile page; nil when no database is set.
	Profiles profile.Store
	onceMu   sync.Mutex
	once     map[string]time.Time

	// Events records changes made here; nil skips it (no database).
	Events audit.Store
	// AdminAccess verifies the Cloudflare Access sign-in in front of /admin;
	// Owners are the emails it admits without the password.
	AdminAccess Identifier
	Owners      []string
	// Tokens manages MCP access tokens; nil hides the connections page.
	Tokens mcp.Tokens
	// Apps lists and revokes AI apps connected with OAuth; nil hides them.
	Apps oauth.Store
	// TeamSignIn: apps are approved by team members through Cloudflare Access.
	TeamSignIn bool
	// MCPURL is the public MCP address shown in setup steps; empty derives it from the request.
	MCPURL string
	// Location is the business time zone for knowledge dates; nil is UTC.
	Location *time.Location
	// Tester runs the reply pipeline for the test page; nil turns that page off.
	Tester Tester
	// Probe sends a tiny test request to a chat provider. Nil uses a real call.
	Probe func(ctx context.Context, p settings.Provider) (llm.Result, error)
	// ProbeEmbedding embeds one word with an embeddings provider. Nil uses a real call.
	ProbeEmbedding func(ctx context.Context, p settings.Provider) error
}

// Routes registers the admin endpoints on mux.
func (h *Handler) Routes(mux *http.ServeMux) {
	protect := http.NewCrossOriginProtection()
	wrap := func(f http.HandlerFunc) http.Handler {
		return secureHeaders(h.requireAuth(protect.Handler(f)))
	}
	mux.Handle("GET /admin", wrap(h.showHome))
	mux.Handle("GET /admin/providers", wrap(h.show))
	mux.Handle("POST /admin/providers", wrap(h.submit))
	mux.Handle("POST /admin/theme", wrap(h.setTheme))
	mux.Handle("GET /admin/connections", wrap(h.showConnections))
	mux.Handle("POST /admin/connections", wrap(h.submitConnections))
	mux.Handle("GET /admin/test", wrap(h.showTest))
	mux.Handle("POST /admin/test", wrap(h.submitTest))
	mux.Handle("GET /admin/knowledge", wrap(h.showKnowledge))
	mux.Handle("POST /admin/knowledge", wrap(h.submitKnowledge))
	mux.Handle("GET /admin/business", wrap(h.showBusiness))
	mux.Handle("POST /admin/business", wrap(h.submitBusiness))
}

type providerView struct {
	BaseURL    string
	Model      string
	KeyMask    string // last 4 of the SAVED key, for the placeholder
	KeyValue   string // key the admin just typed in this request; refilled so Test → Save keeps it
	Configured bool   // a complete provider is saved
}

type testView struct {
	Slot      string
	OK        bool
	Message   string
	Model     string
	LatencyMS int64
}

type pageData struct {
	Primary, Fallback, Embedding providerView
	Saved                        bool
	FallbackOff                  bool // saved, but an incomplete fallback was turned off
	EmbeddingOff                 bool // saved, but an incomplete embeddings provider was turned off
	Error                        string
	Test                         *testView
	Presets                      []preset
}

type preset struct{ Name, URL string }

var presets = []preset{
	{"OpenRouter", "https://openrouter.ai/api/v1"},
	{"OpenAI", "https://api.openai.com/v1"},
}

func view(p settings.Provider) providerView {
	return providerView{BaseURL: p.BaseURL, Model: p.Model, KeyMask: settings.Mask(p.APIKey), Configured: p.Configured()}
}

// editView re-displays a submitted form. URL and model show what was entered;
// the placeholder describes only the saved key (and only while the URL still
// matches it); a key typed in this request is refilled so it is not lost
// between Test and Save. Saved keys are never written into the page.
func editView(entered, saved settings.Provider, typedKey string) providerView {
	v := providerView{
		BaseURL:    entered.BaseURL,
		Model:      entered.Model,
		KeyValue:   typedKey,
		Configured: saved.Configured(),
	}
	if entered.BaseURL == saved.BaseURL {
		v.KeyMask = settings.Mask(saved.APIKey)
	}
	return v
}

func (h *Handler) show(w http.ResponseWriter, r *http.Request) {
	cur := h.Store.Get()
	q := r.URL.Query()
	h.render(w, r, http.StatusOK, pageData{
		Primary: view(cur.Primary), Fallback: view(cur.Fallback), Embedding: view(cur.Embedding),
		Saved:        q.Get("saved") == "1",
		FallbackOff:  q.Get("fallback") == "off",
		EmbeddingOff: q.Get("embedding") == "off",
	})
}

// submit handles both "Save" and the "Test" buttons of the same form.
func (h *Handler) submit(w http.ResponseWriter, r *http.Request) {
	r.Body = http.MaxBytesReader(w, r.Body, 64<<10)
	if err := r.ParseForm(); err != nil {
		http.Error(w, "bad form", http.StatusBadRequest)
		return
	}
	cur := h.Store.Get()
	next := settings.LLM{
		Primary:   fromForm(r, "primary", cur.Primary),
		Fallback:  fromForm(r, "fallback", cur.Fallback),
		Embedding: fromForm(r, "embedding", cur.Embedding),
	}.Normalize()
	// Same provider as primary (e.g. a backup model on one OpenRouter account,
	// or OpenAI embeddings next to an OpenAI chat model): reuse the primary key.
	// Safe because the key goes to the same host.
	next.Fallback = reusePrimaryKey(next.Fallback, next.Primary)
	next.Embedding = reusePrimaryKey(next.Embedding, next.Primary)
	data := pageData{
		Primary:   editView(next.Primary, cur.Primary, r.PostForm.Get("primary_api_key")),
		Fallback:  editView(next.Fallback, cur.Fallback, r.PostForm.Get("fallback_api_key")),
		Embedding: editView(next.Embedding, cur.Embedding, r.PostForm.Get("embedding_api_key")),
	}

	if slot := r.PostForm.Get("test"); slot != "" {
		data.Test = h.runTest(r.Context(), slot, next)
		h.render(w, r, http.StatusOK, data)
		return
	}

	// Fallback and embeddings are optional: an incomplete one is turned off
	// instead of blocking a valid primary.
	var fallbackOff, embeddingOff bool
	next.Fallback, fallbackOff = dropIfIncomplete(next.Fallback)
	next.Embedding, embeddingOff = dropIfIncomplete(next.Embedding)
	if err := h.Store.Save(next); err != nil {
		data.Error = err.Error()
		h.render(w, r, http.StatusUnprocessableEntity, data)
		return
	}
	h.Switch.Set(settings.NewCompleter(h.Store.Get(), h.Timeout, h.Logger))
	if h.Rewrite != nil {
		h.Rewrite.Set(settings.NewCompleter(settings.RewriteSettings(h.Store.Get(), h.RewriteModel), h.Timeout, h.Logger))
	}
	if h.Embedder != nil {
		h.Embedder.Set(settings.NewEmbedder(h.Store.Get(), h.Timeout))
	}
	h.record(r, 0, "providers saved", "chat "+next.Primary.Host()+" "+next.Primary.Model+", embeddings "+next.Embedding.Host()+" "+next.Embedding.Model, nil)
	h.Logger.Info("llm settings updated",
		"primary_host", next.Primary.Host(), "primary_model", next.Primary.Model,
		"fallback_enabled", next.Fallback.Configured(), "fallback_model", next.Fallback.Model,
		"embedding_enabled", next.Embedding.Configured(), "embedding_model", next.Embedding.Model,
		"remote_addr", r.RemoteAddr)
	target := "/admin/providers?saved=1"
	if fallbackOff {
		target += "&fallback=off"
	}
	if embeddingOff {
		target += "&embedding=off"
	}
	http.Redirect(w, r, target, http.StatusSeeOther)
}

// fromForm reads one provider. A blank key keeps the saved one only while the
// base URL is unchanged, so a saved key can never be sent to a new host.
// Clearing URL, key and model removes the provider.
func fromForm(r *http.Request, slot string, saved settings.Provider) settings.Provider {
	p := settings.Provider{
		BaseURL: r.PostForm.Get(slot + "_base_url"),
		APIKey:  r.PostForm.Get(slot + "_api_key"),
		Model:   r.PostForm.Get(slot + "_model"),
	}
	if p.BaseURL == "" && p.Model == "" && p.APIKey == "" {
		return settings.Provider{}
	}
	sameHost := settings.Provider{BaseURL: p.BaseURL}.Normalize().BaseURL == saved.BaseURL
	if p.APIKey == "" && sameHost {
		p.APIKey = saved.APIKey
	}
	return p
}

func reusePrimaryKey(p, primary settings.Provider) settings.Provider {
	if p.APIKey == "" && p.BaseURL != "" && p.BaseURL == primary.BaseURL {
		p.APIKey = primary.APIKey
	}
	return p
}

func dropIfIncomplete(p settings.Provider) (settings.Provider, bool) {
	if p != (settings.Provider{}) && p.Validate() != nil {
		return settings.Provider{}, true
	}
	return p, false
}

func (h *Handler) runTest(ctx context.Context, slot string, s settings.LLM) *testView {
	var p settings.Provider
	switch slot {
	case "fallback":
		p = s.Fallback
	case "embedding":
		p = s.Embedding
	default:
		slot, p = "primary", s.Primary
	}
	tv := &testView{Slot: slot}
	if err := p.Validate(); err != nil || !p.Configured() {
		tv.Message = "Fill in base URL, API key and model first."
		return tv
	}
	if slot == "embedding" {
		return h.runEmbeddingTest(ctx, tv, p)
	}
	probe := h.Probe
	if probe == nil {
		probe = h.realProbe
	}
	started := time.Now()
	res, err := probe(ctx, p)
	tv.LatencyMS = time.Since(started).Milliseconds()
	if err != nil {
		tv.Message = err.Error()
		h.Logger.Warn("llm test failed", "slot", slot, "host", p.Host(), "model", p.Model, "error", err)
		return tv
	}
	tv.OK, tv.Model, tv.Message = true, res.Model, "Connected. The model answered."
	return tv
}

func (h *Handler) runEmbeddingTest(ctx context.Context, tv *testView, p settings.Provider) *testView {
	probe := h.ProbeEmbedding
	if probe == nil {
		probe = func(ctx context.Context, p settings.Provider) error {
			_, err := embedclient.New(p.BaseURL, p.APIKey, p.Model, &http.Client{Timeout: h.Timeout}).Embed(ctx, []string{"ping"})
			return err
		}
	}
	started := time.Now()
	err := probe(ctx, p)
	tv.LatencyMS = time.Since(started).Milliseconds()
	if err != nil {
		tv.Message = err.Error()
		h.Logger.Warn("embedding test failed", "host", p.Host(), "model", p.Model, "error", err)
		return tv
	}
	tv.OK, tv.Model = true, p.Model
	tv.Message = fmt.Sprintf("Connected. The model returned a %d-dimension vector.", embedclient.Dimensions)
	return tv
}

func (h *Handler) realProbe(ctx context.Context, p settings.Provider) (llm.Result, error) {
	c := llm.New(p.BaseURL, p.APIKey, p.Model, &http.Client{Timeout: h.Timeout})
	return c.Complete(ctx, []llm.Message{
		{Role: "system", Content: "Reply with the single word OK."},
		{Role: "user", Content: "ping"},
	})
}

func (h *Handler) render(w http.ResponseWriter, r *http.Request, status int, data pageData) {
	data.Presets = presets
	h.renderPage(w, r, status, "page.html", data)
}

// renderPage executes a clone of the page set with this request's theme, so
// the shared set itself is never executed (html/template cannot clone a set
// after it has run).
func (h *Handler) renderPage(w http.ResponseWriter, r *http.Request, status int, name string, data any) {
	theme := themeOf(r)
	t, err := pages.Clone()
	if err == nil {
		t.Funcs(template.FuncMap{"theme": func() string { return theme }})
		var buf bytes.Buffer
		if err = t.ExecuteTemplate(&buf, name, data); err == nil {
			w.Header().Set("Content-Type", "text/html; charset=utf-8")
			w.WriteHeader(status)
			_, _ = buf.WriteTo(w)
			return
		}
	}
	h.Logger.Error("render admin page", "page", name, "error", err)
	http.Error(w, "page could not be shown", http.StatusInternalServerError)
}

// Identifier verifies a Cloudflare Access token (cfaccess.Verifier).
type Identifier interface {
	Verify(ctx context.Context, token string) (cfaccess.Identity, error)
}

type actorKey struct{}

// record logs one change to the audit trail. Failure only loses history,
// so it is logged and the change stands.
func (h *Handler) record(r *http.Request, acct int64, action, summary string, before any) {
	if h.Events == nil {
		return
	}
	if err := h.Events.Record(r.Context(), audit.Event{AccountID: acct, Actor: actor(r), Action: action, Summary: summary, Before: before}); err != nil {
		h.Logger.Error("admin change not recorded", "account_id", acct, "action", action, "error", err)
	}
}

// actor is who made a change: the owner's email when signed in through
// Cloudflare Access, else "admin password".
func actor(r *http.Request) string {
	if a, ok := r.Context().Value(actorKey{}).(string); ok && a != "" {
		return a
	}
	return "admin password"
}

func (h *Handler) isOwner(email string) bool {
	for _, o := range h.Owners {
		if o == email {
			return true
		}
	}
	return false
}

// requireAuth admits the owner. With Cloudflare Access in front of /admin
// (AdminAccess set), a verified Access sign-in for an owner email is enough:
// no password. A request without the Access header (e.g. through the SSH
// tunnel) still needs the Basic Auth password. A present but invalid Access
// token, or a signed-in person who is not an owner, is refused.
func (h *Handler) requireAuth(next http.Handler) http.Handler {
	want := sha256.Sum256([]byte(h.Password))
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if h.AdminAccess != nil {
			if tok := r.Header.Get(cfaccess.Header); tok != "" {
				id, err := h.AdminAccess.Verify(r.Context(), tok)
				switch {
				case err != nil:
					h.Logger.Warn("admin: invalid cloudflare access token", "remote_addr", r.RemoteAddr)
					http.Error(w, "your Cloudflare sign-in could not be verified; reload the page", http.StatusForbidden)
					return
				case !h.isOwner(id.Email):
					h.Logger.Warn("admin: signed-in person is not an owner", "remote_addr", r.RemoteAddr)
					http.Error(w, id.Email+" is not an owner of this admin page", http.StatusForbidden)
					return
				}
				next.ServeHTTP(w, r.WithContext(context.WithValue(r.Context(), actorKey{}, id.Email)))
				return
			}
		}
		user, pass, ok := r.BasicAuth()
		got := sha256.Sum256([]byte(pass))
		if !ok || user != Username || subtle.ConstantTimeCompare(got[:], want[:]) != 1 {
			if ok {
				h.Logger.Warn("admin login failed", "remote_addr", r.RemoteAddr)
			}
			w.Header().Set("WWW-Authenticate", `Basic realm="ai-service admin", charset="UTF-8"`)
			http.Error(w, "authentication required", http.StatusUnauthorized)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func secureHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		h := w.Header()
		h.Set("Content-Security-Policy", "default-src 'none'; style-src 'unsafe-inline'; form-action 'self'; frame-ancestors 'self'; base-uri 'none'")
		h.Set("X-Content-Type-Options", "nosniff")
		h.Set("Referrer-Policy", "no-referrer")
		h.Set("Cache-Control", "no-store")
		next.ServeHTTP(w, r)
	})
}
