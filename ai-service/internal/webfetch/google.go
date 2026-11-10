package webfetch

import (
	"errors"
	"net/url"
	"regexp"
	"strings"
)

// ErrGoogleSignIn means Google asked for a sign-in: the file is not shared
// with "Anyone with the link" and not published to the web.
var ErrGoogleSignIn = errors.New("Google asks for a sign-in to open this file. In Google, set Share → General access to \"Anyone with the link\" (Viewer), or use File → Share → Publish to web")

var (
	googleFile = regexp.MustCompile(`^/(spreadsheets|document)/d/([A-Za-z0-9_-]+)(/[a-z]*)?/?$`)
	googleGid  = regexp.MustCompile(`^[0-9]+$`)
)

// GoogleExport turns a Google Sheets or Docs link copied from the address bar
// (…/edit, …/view) into the file's download link: a sheet tab as CSV (data
// is true) or a document as plain text. Published links (/d/e/…) and
// anything else are left alone (ok is false). The file must be shared with
// "Anyone with the link", or Google answers with a sign-in page.
func GoogleExport(u *url.URL) (export *url.URL, data, ok bool) {
	if u.Scheme != "https" || strings.ToLower(u.Hostname()) != "docs.google.com" || u.Port() != "" {
		return nil, false, false
	}
	m := googleFile.FindStringSubmatch(u.Path)
	if m == nil || m[2] == "e" { // "/d/e/…" is a published link, which works as is
		return nil, false, false
	}
	out := &url.URL{Scheme: "https", Host: "docs.google.com", Path: "/" + m[1] + "/d/" + m[2] + "/export"}
	if m[1] == "document" {
		out.RawQuery = "format=txt"
		return out, false, true
	}
	q := "format=csv"
	if gid := u.Query().Get("gid"); gid != "" {
		if !googleGid.MatchString(gid) {
			return nil, false, false
		}
		q += "&gid=" + gid
	}
	out.RawQuery = q
	return out, true, true
}

// googleSignIn reports a redirect from a Google file to Google's sign-in page.
func googleSignIn(from, to string) bool {
	return from == "docs.google.com" && to == "accounts.google.com"
}
