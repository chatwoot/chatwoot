package webfetch

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"net/netip"
	"strings"
	"testing"
)

func TestPublic(t *testing.T) {
	cases := map[string]bool{
		"8.8.8.8": true, "1.1.1.1": true, "2606:4700::1111": true,
		"127.0.0.1": false, "10.1.2.3": false, "172.16.0.1": false, "192.168.1.1": false,
		"169.254.169.254": false, "100.64.0.1": false, "0.0.0.0": false, "::1": false,
		"fe80::1": false, "fc00::1": false, "::ffff:127.0.0.1": false, "64:ff9b::a00:1": false, "224.0.0.1": false,
	}
	for ip, want := range cases {
		// Act
		got := Public(netip.MustParseAddr(ip))

		// Assert
		if got != want {
			t.Errorf("Public(%s) = %v, want %v", ip, got, want)
		}
	}
}

func TestCheckURL(t *testing.T) {
	ok := []string{"https://www.johnstockeraistudio.com/legal/refund", "http://example.com/page"}
	bad := []string{"ftp://example.com/x", "javascript:alert(1)", "https://user:pw@example.com/", "http://127.0.0.1/", "http://10.0.0.5/",
		"http://169.254.169.254/latest/meta-data/", "http://[::1]/", "http://localhost/", "http://db.internal/", "http://example.com:8080/", "not a url", "https:///nohost"}
	for _, u := range ok {
		if _, err := CheckURL(u); err != nil {
			t.Errorf("CheckURL(%q) = %v", u, err)
		}
	}
	for _, u := range bad {
		if _, err := CheckURL(u); err == nil {
			t.Errorf("CheckURL(%q) accepted", u)
		}
	}
}

func TestDialAllowed_ChecksTheResolvedAddress(t *testing.T) {
	cases := map[string]bool{"93.184.216.34:443": true, "93.184.216.34:80": true, "93.184.216.34:22": false,
		"127.0.0.1:443": false, "10.0.0.1:443": false, "[::1]:443": false, "169.254.169.254:80": false}
	for addr, want := range cases {
		// Act
		err := dialAllowed(addr, false)

		// Assert
		if (err == nil) != want {
			t.Errorf("dialAllowed(%s) = %v, want allowed=%v", addr, err, want)
		}
	}
}

func TestFetch_DefaultRefusesLocalServer(t *testing.T) {
	// Arrange: a server on 127.0.0.1, reached by IP and through a redirect from "outside".
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { _, _ = w.Write([]byte("secret")) }))
	defer srv.Close()

	// Act
	_, err := (&Fetcher{}).Fetch(context.Background(), srv.URL)

	// Assert
	if !errors.Is(err, ErrBlocked) {
		t.Fatalf("err = %v, want ErrBlocked", err)
	}
}

func TestFetch_Outcomes(t *testing.T) {
	// Arrange
	mux := http.NewServeMux()
	mux.HandleFunc("/ok", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		_, _ = w.Write([]byte("<html><title>T</title><body><p>hi</p></body></html>"))
	})
	mux.HandleFunc("/gone", func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusGone) })
	mux.HandleFunc("/boom", func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusInternalServerError) })
	mux.HandleFunc("/pdf", func(w http.ResponseWriter, _ *http.Request) { w.Header().Set("Content-Type", "application/pdf") })
	mux.HandleFunc("/big", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "text/plain")
		_, _ = w.Write([]byte(strings.Repeat("a", MaxBytes+10)))
	})
	mux.HandleFunc("/loop", func(w http.ResponseWriter, r *http.Request) { http.Redirect(w, r, "/loop", http.StatusFound) })
	srv := httptest.NewServer(mux)
	defer srv.Close()
	f := &Fetcher{AllowPrivate: true}
	cases := map[string]error{"/gone": ErrNotFound, "/pdf": ErrNotText, "/big": ErrTooLarge}

	// Act / Assert
	if p, err := f.Fetch(context.Background(), srv.URL+"/ok"); err != nil || p.ContentType != "text/html" {
		t.Fatalf("ok: %v %+v", err, p)
	}
	for path, want := range cases {
		if _, err := f.Fetch(context.Background(), srv.URL+path); !errors.Is(err, want) {
			t.Errorf("%s: err = %v, want %v", path, err, want)
		}
	}
	if _, err := f.Fetch(context.Background(), srv.URL+"/boom"); !errors.Is(err, ErrBadResponse) {
		t.Errorf("boom: %v", err)
	}
	if _, err := f.Fetch(context.Background(), srv.URL+"/loop"); err == nil || strings.Contains(err.Error(), srv.URL) {
		t.Errorf("redirect loop: %v (must fail without echoing the URL)", err)
	}
}

func TestText_KeepsContentDropsChrome(t *testing.T) {
	// Arrange
	page := Page{ContentType: "text/html", Body: []byte(`<html><head><title> นโยบายการคืนเงิน </title><style>p{}</style></head>
<body><nav>เมนูหลัก หน้าแรก</nav><header>โลโก้</header>
<main><h1>นโยบายการคืนเงิน</h1><p>สินค้าดิจิทัล   ไม่รับคืน</p>
<h2>ข้อยกเว้น</h2><ul><li>ไฟล์เสีย</li><li>ชำระซ้ำ</li></ul>
<table><tr><td>แพ็กเกจ</td><td>3,900</td></tr></table>
<div hidden>ซ่อน</div><p style="display: none">ซ่อนอีก</p><script>alert(1)</script></main>
<footer>© 2026</footer></body></html>`)}

	// Act
	title, text := Text(page)

	// Assert
	if title != "นโยบายการคืนเงิน" {
		t.Errorf("title = %q", title)
	}
	for _, want := range []string{"# นโยบายการคืนเงิน", "สินค้าดิจิทัล ไม่รับคืน", "## ข้อยกเว้น", "- ไฟล์เสีย", "- ชำระซ้ำ", "| แพ็กเกจ | 3,900"} {
		if !strings.Contains(text, want) {
			t.Errorf("missing %q in:\n%s", want, text)
		}
	}
	for _, bad := range []string{"เมนูหลัก", "โลโก้", "ซ่อน", "alert", "© 2026", "p{}"} {
		if strings.Contains(text, bad) {
			t.Errorf("kept %q", bad)
		}
	}
}

func TestText_ReactStreamedContentAndLoadingPlaceholders(t *testing.T) {
	// Arrange: the shape of johnstockeraistudio.com pages (Next.js streaming).
	page := Page{ContentType: "text/html", Body: []byte(`<html><head><title>AI Studio — site-wide title</title></head><body>
<div role="status" aria-live="polite"><span class="sr-only">กำลังโหลดเนื้อหา...</span></div>
<div hidden id="S:4"><main><h1>นโยบายการคืนเงิน (Refund Policy)</h1><p>ไม่รับเปลี่ยนหรือคืนเงินในทุกกรณี</p></main></div>
<div hidden>still hidden</div></body></html>`)}

	// Act
	title, text := Text(page)

	// Assert
	if title != "นโยบายการคืนเงิน (Refund Policy)" {
		t.Errorf("title = %q, want the page heading", title)
	}
	if !strings.Contains(text, "ไม่รับเปลี่ยนหรือคืนเงินในทุกกรณี") || strings.Contains(text, "กำลังโหลด") || strings.Contains(text, "still hidden") {
		t.Errorf("text = %q", text)
	}
}
