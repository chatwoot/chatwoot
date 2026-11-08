package media

import (
	"context"
	"io"
	"mime"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"
)

func host(t *testing.T, srv *httptest.Server) string {
	u, _ := url.Parse(srv.URL)
	return u.Host
}

func TestFetchOnlyFromTheChatwootHost(t *testing.T) {
	// Arrange
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "image/png")
		_, _ = w.Write([]byte("PNGDATA"))
	}))
	defer srv.Close()
	other := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { _, _ = w.Write([]byte("x")) }))
	defer other.Close()
	f := &Fetcher{Host: host(t, srv), MaxBytes: 1 << 20, AllowHTTP: true}

	// Act
	body, ctype, err := f.Fetch(context.Background(), srv.URL+"/rails/active_storage/blobs/x.png", 1<<20)
	_, _, errOther := f.Fetch(context.Background(), other.URL+"/evil", 1<<20)
	_, _, errMeta := f.Fetch(context.Background(), "http://169.254.169.254/latest/meta-data", 1<<20)

	// Assert
	if err != nil || string(body) != "PNGDATA" || ctype != "image/png" {
		t.Fatalf("fetch = %q %q %v", body, ctype, err)
	}
	if errOther == nil || errMeta == nil {
		t.Error("any other host must be refused (SSRF)")
	}
}

func TestFetchRefusesRedirectsOffHost(t *testing.T) {
	// Arrange: the Chatwoot host redirects to another host.
	other := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { _, _ = w.Write([]byte("secret")) }))
	defer other.Close()
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/same" {
			http.Redirect(w, r, "/final", http.StatusFound)
			return
		}
		if r.URL.Path == "/final" {
			_, _ = w.Write([]byte("ok"))
			return
		}
		http.Redirect(w, r, other.URL+"/x", http.StatusFound)
	}))
	defer srv.Close()
	f := &Fetcher{Host: host(t, srv), MaxBytes: 1 << 20, AllowHTTP: true}

	// Act
	same, _, errSame := f.Fetch(context.Background(), srv.URL+"/same", 1<<20)
	_, _, errOff := f.Fetch(context.Background(), srv.URL+"/off", 1<<20)

	// Assert
	if errSame != nil || string(same) != "ok" {
		t.Errorf("same-host redirect = %q %v", same, errSame)
	}
	if errOff == nil {
		t.Error("a redirect to another host must be refused")
	}
}

func TestFetchEnforcesSizeAndHTTPS(t *testing.T) {
	// Arrange
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, _ = w.Write([]byte(strings.Repeat("a", 2048)))
	}))
	defer srv.Close()
	small := &Fetcher{Host: host(t, srv), MaxBytes: 1024, AllowHTTP: true}
	strict := &Fetcher{Host: host(t, srv), MaxBytes: 1 << 20}

	// Act
	_, _, errBig := small.Fetch(context.Background(), srv.URL+"/big", 1<<20)
	_, _, errHTTP := strict.Fetch(context.Background(), srv.URL+"/big", 1<<20)

	// Assert
	if errBig == nil {
		t.Error("a file over MaxBytes must be refused")
	}
	if errHTTP == nil {
		t.Error("plain http must be refused unless AllowHTTP (tests only)")
	}
}

func TestTranscribe(t *testing.T) {
	// Arrange
	var gotModel, gotFile, gotAuth string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotAuth = r.Header.Get("Authorization")
		_, params, _ := mime.ParseMediaType(r.Header.Get("Content-Type"))
		mr := multipart.NewReader(r.Body, params["boundary"])
		for {
			p, err := mr.NextPart()
			if err != nil {
				break
			}
			b, _ := io.ReadAll(p)
			switch p.FormName() {
			case "model":
				gotModel = string(b)
			case "file":
				gotFile = p.FileName() + ":" + string(b)
			}
		}
		_, _ = w.Write([]byte(`{"text":" ผ่อนได้ไหมคะ "}`))
	}))
	defer srv.Close()
	tr := &Transcriber{BaseURL: srv.URL, APIKey: "k", Model: "gpt-4o-mini-transcribe"}

	// Act
	text, err := tr.Transcribe(context.Background(), []byte("AUDIO"), "voice.m4a")

	// Assert
	if err != nil || text != "ผ่อนได้ไหมคะ" {
		t.Fatalf("transcribe = %q %v", text, err)
	}
	if gotModel != "gpt-4o-mini-transcribe" || gotFile != "voice.m4a:AUDIO" || gotAuth != "Bearer k" {
		t.Errorf("request model=%q file=%q auth=%q", gotModel, gotFile, gotAuth)
	}
}

func TestTranscribeProviderError(t *testing.T) {
	// Arrange
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusBadRequest)
		_, _ = w.Write([]byte(`{"error":{"message":"bad audio"}}`))
	}))
	defer srv.Close()

	// Act
	_, err := (&Transcriber{BaseURL: srv.URL, APIKey: "k", Model: "m"}).Transcribe(context.Background(), []byte("x"), "a.ogg")

	// Assert
	if err == nil {
		t.Fatal("a 400 must be an error")
	}
}

func TestTranscribeSendsVocabularyPrompt(t *testing.T) {
	// Arrange
	var gotPrompt string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_ = r.ParseMultipartForm(1 << 20)
		gotPrompt = r.FormValue("prompt")
		_, _ = w.Write([]byte(`{"text":"ok"}`))
	}))
	defer srv.Close()

	// Act
	_, err := (&Transcriber{BaseURL: srv.URL, APIKey: "k", Model: "m", Prompt: "Johnstocker AI Studio, AutoCut"}).Transcribe(context.Background(), []byte("x"), "a.m4a")

	// Assert
	if err != nil || gotPrompt != "Johnstocker AI Studio, AutoCut" {
		t.Errorf("prompt = %q, err %v", gotPrompt, err)
	}
}

func TestFetchPerCallLimit(t *testing.T) {
	// Arrange: a 2 KB file, a 1 MB fetcher, a 1 KB call limit (images use 5 MB of 10).
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, _ = w.Write([]byte(strings.Repeat("a", 2048)))
	}))
	defer srv.Close()
	f := &Fetcher{Host: host(t, srv), MaxBytes: 1 << 20, AllowHTTP: true}

	// Act
	_, _, err := f.Fetch(context.Background(), srv.URL+"/x", 1024)

	// Assert
	if err == nil {
		t.Error("the per-call limit must apply when smaller than MaxBytes")
	}
}

func TestAllowedRefusesURLTricks(t *testing.T) {
	// Arrange
	f := &Fetcher{Host: "chat.example.com", MaxBytes: 1 << 20}
	empty := &Fetcher{MaxBytes: 1 << 20}
	cases := []string{
		"https://chat.example.com@evil.com/x", // userinfo: real host is evil.com
		"https://chat.example.com:8443/x",     // same name, other port
		"http://chat.example.com/x",           // downgrade to http
		"https://evil.com/?h=chat.example.com",
		"https://chat.example.com.evil.com/x",
		"//chat.example.com/x",
	}

	// Act + Assert
	for _, raw := range cases {
		if f.allowed(raw) == nil {
			t.Errorf("allowed(%q) = nil, want refused", raw)
		}
	}
	if f.allowed("https://chat.example.com/rails/active_storage/x") != nil {
		t.Error("the Chatwoot host itself must be allowed")
	}
	if empty.allowed("https://chat.example.com/x") == nil {
		t.Error("an unset host must refuse everything")
	}
}

func TestFetchPublicHostLinkGoesToChatwootHost(t *testing.T) {
	// Arrange: local Docker, where Chatwoot writes localhost:3000 into links
	// but the bot reaches it as rails:3000.
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, _ = w.Write([]byte("IMG" + r.URL.Path))
	}))
	defer srv.Close()
	f := &Fetcher{Host: host(t, srv), PublicHost: "localhost:3000", MaxBytes: 1 << 20, AllowHTTP: true}

	// Act
	body, _, err := f.Fetch(context.Background(), "http://localhost:3000/rails/active_storage/x.png", 1<<20)

	// Assert
	if err != nil || string(body) != "IMG/rails/active_storage/x.png" {
		t.Fatalf("fetch = %q %v, want the file from the Chatwoot host", body, err)
	}
}

func TestPublicHostDoesNotWidenWhatIsAllowed(t *testing.T) {
	// Arrange
	f := &Fetcher{Host: "rails:3000", PublicHost: "localhost:3000", MaxBytes: 1 << 20}
	unset := &Fetcher{Host: "rails:3000", MaxBytes: 1 << 20}

	// Act + Assert
	for _, raw := range []string{
		"https://localhost:3000@evil.com/x",
		"https://localhost:3001/x",
		"https://evil.com/?h=localhost:3000",
		"http://localhost:3000/x", // https still required unless AllowHTTP
	} {
		if f.allowed(raw) == nil {
			t.Errorf("allowed(%q) = nil, want refused", raw)
		}
	}
	if f.allowed("https://localhost:3000/x") != nil {
		t.Error("the public Chatwoot host must be allowed")
	}
	if unset.allowed("https://localhost:3000/x") == nil {
		t.Error("without PublicHost only the Chatwoot host is allowed")
	}
}

func TestFetchFollowsRedirectOnPublicHost(t *testing.T) {
	// Arrange: Chatwoot answers a blob link with a redirect to the file,
	// written with the public host again.
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/blob" {
			http.Redirect(w, r, "http://localhost:3000/disk/file.png", http.StatusFound)
			return
		}
		_, _ = w.Write([]byte("FILE" + r.URL.Path))
	}))
	defer srv.Close()
	f := &Fetcher{Host: host(t, srv), PublicHost: "localhost:3000", MaxBytes: 1 << 20, AllowHTTP: true}

	// Act
	body, _, err := f.Fetch(context.Background(), "http://localhost:3000/blob", 1<<20)

	// Assert
	if err != nil || string(body) != "FILE/disk/file.png" {
		t.Fatalf("fetch = %q %v, want the redirected file from the Chatwoot host", body, err)
	}
}

func TestFetchHTTPSPublicLinkUsesHostScheme(t *testing.T) {
	// Arrange: staging, where links say https://stg.example.com but the bot
	// reaches Chatwoot as http://stg-rails:3000.
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, _ = w.Write([]byte("OK"))
	}))
	defer srv.Close()
	f := &Fetcher{Host: host(t, srv), PublicHost: "stg.example.com", HostScheme: "http", MaxBytes: 1 << 20}

	// Act
	body, _, err := f.Fetch(context.Background(), "https://stg.example.com/rails/active_storage/x", 1<<20)

	// Assert
	if err != nil || string(body) != "OK" {
		t.Fatalf("fetch = %q %v, want the file over http from the Chatwoot host", body, err)
	}
}

func TestPublicHostRefusesRedirectToAnotherHost(t *testing.T) {
	// Arrange
	hit := false
	other := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { hit = true }))
	defer other.Close()
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		http.Redirect(w, r, other.URL+"/evil", http.StatusFound)
	}))
	defer srv.Close()
	f := &Fetcher{Host: host(t, srv), PublicHost: "localhost:3000", HostScheme: "http", MaxBytes: 1 << 20, AllowHTTP: true}

	// Act
	_, _, err := f.Fetch(context.Background(), "http://localhost:3000/blob", 1<<20)

	// Assert
	if err == nil || hit {
		t.Fatalf("err = %v, other host hit = %v; want refused before any request", err, hit)
	}
}

func TestProductionShapeRefusesHTTPRedirect(t *testing.T) {
	// Arrange: no PublicHost, https only, as in production.
	f := &Fetcher{Host: "chat.example.com", MaxBytes: 1 << 20}

	// Act + Assert
	if f.allowed("http://chat.example.com/disk/x") == nil {
		t.Error("an http hop must be refused without AllowHTTP")
	}
	if f.internal("https://chat.example.com/x") != "https://chat.example.com/x" {
		t.Error("without PublicHost links must not be rewritten")
	}
}

func TestFetchRetriesWhileTheFileIsStillUploading(t *testing.T) {
	// Arrange: Chatwoot sends the webhook before the upload finishes, so the
	// first requests answer 404.
	calls := 0
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		calls++
		if calls < 3 {
			http.NotFound(w, r)
			return
		}
		_, _ = w.Write([]byte("VOICE"))
	}))
	defer srv.Close()
	f := &Fetcher{Host: host(t, srv), MaxBytes: 1 << 20, AllowHTTP: true, RetryWait: time.Millisecond}

	// Act
	body, _, err := f.Fetch(context.Background(), srv.URL+"/blob", 1<<20)

	// Assert
	if err != nil || string(body) != "VOICE" || calls != 3 {
		t.Fatalf("fetch = %q %v after %d calls, want the file on the third try", body, err, calls)
	}
}

func TestFetchGivesUpOnAMissingFile(t *testing.T) {
	// Arrange
	calls := 0
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		calls++
		http.NotFound(w, r)
	}))
	defer srv.Close()
	f := &Fetcher{Host: host(t, srv), MaxBytes: 1 << 20, AllowHTTP: true, RetryWait: time.Millisecond}

	// Act
	_, _, err := f.Fetch(context.Background(), srv.URL+"/gone", 1<<20)

	// Assert
	if err == nil || calls != 4 {
		t.Fatalf("err = %v after %d calls, want an error after 4 tries", err, calls)
	}
}
