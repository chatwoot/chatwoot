// Package webfetch downloads public web pages for the knowledge base without
// letting a URL reach internal services (SSRF): only http and https on ports
// 80 and 443, and every connection — including each redirect — is checked
// against the address actually dialled, so DNS tricks cannot point it at a
// private, loopback, link-local or cloud-metadata address.
package webfetch

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"mime"
	"net"
	"net/http"
	"net/netip"
	"net/url"
	"strings"
	"sync"
	"syscall"
	"time"
	"unicode/utf8"

	"golang.org/x/net/html/charset"
)

// Limits.
const (
	MaxBytes     = 2 << 20
	MaxRedirects = 5
	Timeout      = 20 * time.Second
)

// Errors.
var (
	ErrBlocked     = errors.New("address not allowed (only public web pages)")
	ErrNotText     = errors.New("not a web page or text file")
	ErrTooLarge    = errors.New("page larger than 2 MB")
	ErrNotFound    = errors.New("page not found (404 or 410)")
	ErrBadResponse = errors.New("the site returned an error")
)

// Page is a fetched document.
type Page struct {
	FinalURL    string
	ContentType string // text/html, text/plain or text/markdown
	Body        []byte
}

// blocked lists prefixes that are never public.
var blocked = []netip.Prefix{
	netip.MustParsePrefix("0.0.0.0/8"),
	netip.MustParsePrefix("100.64.0.0/10"), // carrier-grade NAT
	netip.MustParsePrefix("192.0.0.0/24"),
	netip.MustParsePrefix("198.18.0.0/15"), // benchmarking
	netip.MustParsePrefix("240.0.0.0/4"),
	netip.MustParsePrefix("64:ff9b::/96"), // NAT64 can map to private IPv4
	netip.MustParsePrefix("2001:db8::/32"),
	netip.MustParsePrefix("::/96"),          // IPv4-compatible
	netip.MustParsePrefix("fec0::/10"),      // site-local (deprecated)
	netip.MustParsePrefix("2002::/16"),      // 6to4 can embed private IPv4
	netip.MustParsePrefix("192.88.99.0/24"), // 6to4 relay
}

// Public reports whether ip is a public unicast address.
func Public(ip netip.Addr) bool {
	ip = ip.Unmap()
	if !ip.IsValid() || ip.IsLoopback() || ip.IsPrivate() || ip.IsLinkLocalUnicast() || ip.IsLinkLocalMulticast() ||
		ip.IsMulticast() || ip.IsUnspecified() || ip.IsInterfaceLocalMulticast() || !ip.IsGlobalUnicast() {
		return false
	}
	for _, p := range blocked {
		if p.Contains(ip) {
			return false
		}
	}
	return true
}

// Fetcher downloads pages. The zero value is ready; tests can set Client.
type Fetcher struct {
	Client *http.Client
	// AllowPrivate is for tests against a local server only.
	AllowPrivate bool
	UserAgent    string

	once sync.Once
	c    *http.Client
}

func (f *Fetcher) client() *http.Client {
	if f.Client != nil {
		return f.Client
	}
	f.once.Do(func() { f.c = f.build() })
	return f.c
}

func (f *Fetcher) build() *http.Client {
	dialer := &net.Dialer{Timeout: 10 * time.Second, Control: func(_, address string, _ syscall.RawConn) error {
		return dialAllowed(address, f.AllowPrivate)
	}}
	tr := &http.Transport{
		DialContext:           dialer.DialContext,
		Proxy:                 nil, // never through an environment proxy
		TLSHandshakeTimeout:   10 * time.Second,
		ResponseHeaderTimeout: 15 * time.Second,
		MaxIdleConns:          10,
		IdleConnTimeout:       30 * time.Second,
	}
	return &http.Client{
		Transport: tr,
		Timeout:   Timeout,
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			return checkRedirect(req.URL, via, f.AllowPrivate)
		},
	}
}

// ErrOffSite means a page redirected to another website.
var ErrOffSite = errors.New("the page redirects to another website")

// checkRedirect keeps redirects on the same site (the host, with or without
// "www."), never from https to http: a page that starts redirecting elsewhere
// (an expired domain, a hijacked site) must not replace the knowledge.
func checkRedirect(next *url.URL, via []*http.Request, allowPrivate bool) error {
	if len(via) >= MaxRedirects {
		return errors.New("too many redirects")
	}
	first := via[0].URL
	if first.Scheme == "https" && next.Scheme != "https" {
		return ErrOffSite
	}
	site := func(h string) string { return strings.TrimPrefix(strings.ToLower(strings.TrimSuffix(h, ".")), "www.") }
	if googleSignIn(site(first.Hostname()), site(next.Hostname())) {
		return ErrGoogleSignIn
	}
	if site(next.Hostname()) != site(first.Hostname()) && !googleHop(site(first.Hostname()), site(next.Hostname()), next.Scheme) {
		return ErrOffSite
	}
	return checkURL(next, allowPrivate)
}

// googleHop allows the one cross-site redirect Google uses for files
// published to the web: docs.google.com hands the download to
// *.googleusercontent.com over https.
func googleHop(from, to, scheme string) bool {
	return from == "docs.google.com" && scheme == "https" && strings.HasSuffix(to, ".googleusercontent.com")
}

// dialAllowed is checked on the address actually being connected to, after
// DNS resolution, for the first request and every redirect.
func dialAllowed(address string, allowPrivate bool) error {
	if allowPrivate {
		return nil
	}
	ap, err := netip.ParseAddrPort(address)
	if err != nil || !Public(ap.Addr()) {
		return ErrBlocked
	}
	if p := ap.Port(); p != 80 && p != 443 {
		return ErrBlocked
	}
	return nil
}

// CheckURL validates a URL an owner wants to add and normalises it: lower-case
// scheme and host, no fragment, no whitespace, at most 496 characters.
func CheckURL(raw string) (*url.URL, error) {
	raw = strings.TrimSpace(raw)
	if strings.ContainsAny(raw, " \t\r\n") {
		return nil, errors.New("the address must not contain spaces")
	}
	u, err := url.Parse(raw)
	if err != nil {
		return nil, errors.New("not a valid web address")
	}
	u.Scheme, u.Host, u.Fragment, u.RawFragment = strings.ToLower(u.Scheme), strings.ToLower(u.Host), "", ""
	if err := checkURL(u, false); err != nil {
		return nil, err
	}
	if len([]rune(u.String())) > 496 {
		return nil, errors.New("the address is too long (496 characters at most)")
	}
	return u, nil
}

func checkURL(u *url.URL, allowPrivate bool) error {
	switch {
	case u.Scheme != "http" && u.Scheme != "https":
		return errors.New("the address must start with http:// or https://")
	case u.Host == "" || u.User != nil:
		return errors.New("not a valid web address")
	case !allowPrivate && u.Port() != "" && u.Port() != "80" && u.Port() != "443":
		return ErrBlocked
	}
	if ip, err := netip.ParseAddr(strings.Trim(u.Hostname(), "[]")); err == nil && !allowPrivate && !Public(ip) {
		return ErrBlocked
	}
	h := strings.ToLower(u.Hostname())
	if !allowPrivate && (h == "localhost" || strings.HasSuffix(h, ".localhost") || strings.HasSuffix(h, ".local") || strings.HasSuffix(h, ".internal")) {
		return ErrBlocked
	}
	return nil
}

// Fetch downloads one page.
func (f *Fetcher) Fetch(ctx context.Context, raw string) (Page, error) {
	return f.fetch(ctx, raw, "text/html, text/plain, text/markdown;q=0.9", pageType)
}

// FetchData downloads a data file (CSV or JSON Lines). Body is returned as
// UTF-8 text; parsing is the caller's job.
func (f *Fetcher) FetchData(ctx context.Context, raw string) (Page, error) {
	return f.fetch(ctx, raw, "text/csv, application/x-ndjson, application/jsonl, text/plain;q=0.8, */*;q=0.1", dataType)
}

func pageType(ct string) bool {
	return ct == "text/html" || ct == "text/plain" || ct == "text/markdown" || ct == "application/xhtml+xml"
}

// dataType accepts the types data files are served as. octet-stream is
// common for .jsonl files; the content must still parse as CSV or JSON Lines.
func dataType(ct string) bool {
	switch ct {
	case "text/csv", "text/plain", "text/tab-separated-values", "application/json", "application/x-ndjson",
		"application/jsonl", "application/jsonlines", "application/x-jsonlines", "application/octet-stream":
		return true
	}
	return false
}

func (f *Fetcher) fetch(ctx context.Context, raw, accept string, allowed func(string) bool) (Page, error) {
	u, err := url.Parse(strings.TrimSpace(raw))
	if err != nil {
		return Page{}, errors.New("not a valid web address")
	}
	if err := checkURL(u, f.AllowPrivate); err != nil {
		return Page{}, err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, u.String(), nil)
	if err != nil {
		return Page{}, err
	}
	ua := f.UserAgent
	if ua == "" {
		ua = "ai-service-knowledge-sync/1"
	}
	req.Header.Set("User-Agent", ua)
	req.Header.Set("Accept", accept)
	res, err := f.client().Do(req)
	if err != nil {
		if errors.Is(err, ErrBlocked) {
			return Page{}, ErrBlocked
		}
		if errors.Is(err, ErrGoogleSignIn) {
			return Page{}, ErrGoogleSignIn
		}
		if errors.Is(err, ErrOffSite) {
			return Page{}, ErrOffSite
		}
		return Page{}, fmt.Errorf("could not reach the site: %w", unwrapNetErr(err))
	}
	defer res.Body.Close()
	switch {
	case res.StatusCode == http.StatusNotFound || res.StatusCode == http.StatusGone:
		return Page{}, ErrNotFound
	case res.StatusCode != http.StatusOK:
		return Page{}, fmt.Errorf("%w (status %d)", ErrBadResponse, res.StatusCode)
	}
	ct, params, _ := mime.ParseMediaType(res.Header.Get("Content-Type"))
	if !allowed(ct) {
		return Page{}, ErrNotText
	}
	body, err := io.ReadAll(io.LimitReader(res.Body, MaxBytes+1))
	if err != nil {
		return Page{}, fmt.Errorf("could not read the page: %w", unwrapNetErr(err))
	}
	if len(body) > MaxBytes {
		return Page{}, ErrTooLarge
	}
	if ct == "application/xhtml+xml" {
		ct = "text/html"
	}
	// Decode legacy encodings (e.g. Thai TIS-620 / windows-874) to UTF-8.
	if dec, err := charsetReader(body, params["charset"], ct); err == nil {
		body = dec
	}
	if !utf8.Valid(body) {
		return Page{}, errors.New("the page is not readable text")
	}
	return Page{FinalURL: res.Request.URL.String(), ContentType: ct, Body: body}, nil
}

func charsetReader(body []byte, label, ct string) ([]byte, error) {
	if utf8.Valid(body) && (label == "" || strings.EqualFold(label, "utf-8")) {
		return body, nil
	}
	r, err := charset.NewReader(bytes.NewReader(body), ct+"; charset="+label)
	if err != nil {
		return nil, err
	}
	return io.ReadAll(io.LimitReader(r, 4*MaxBytes))
}

// unwrapNetErr drops the URL from errors so logs and pages show the reason only.
func unwrapNetErr(err error) error {
	var ue *url.Error
	if errors.As(err, &ue) {
		return ue.Err
	}
	return err
}
