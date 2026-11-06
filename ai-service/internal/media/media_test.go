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
	body, ctype, err := f.Fetch(context.Background(), srv.URL+"/rails/active_storage/blobs/x.png")
	_, _, errOther := f.Fetch(context.Background(), other.URL+"/evil")
	_, _, errMeta := f.Fetch(context.Background(), "http://169.254.169.254/latest/meta-data")

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
	same, _, errSame := f.Fetch(context.Background(), srv.URL+"/same")
	_, _, errOff := f.Fetch(context.Background(), srv.URL+"/off")

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
	_, _, errBig := small.Fetch(context.Background(), srv.URL+"/big")
	_, _, errHTTP := strict.Fetch(context.Background(), srv.URL+"/big")

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
