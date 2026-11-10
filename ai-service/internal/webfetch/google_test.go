package webfetch

import (
	"errors"
	"net/http"
	"net/url"
	"testing"
)

func TestGoogleExport_TurnsEditLinksIntoDownloads(t *testing.T) {
	cases := []struct {
		in, want string
		data, ok bool
	}{
		{"https://docs.google.com/spreadsheets/d/1AbC_d-9/edit?gid=1666453564", "https://docs.google.com/spreadsheets/d/1AbC_d-9/export?format=csv&gid=1666453564", true, true},
		{"https://docs.google.com/spreadsheets/d/1AbC_d-9/edit", "https://docs.google.com/spreadsheets/d/1AbC_d-9/export?format=csv", true, true},
		{"https://docs.google.com/spreadsheets/d/1AbC_d-9/view?usp=sharing&gid=7", "https://docs.google.com/spreadsheets/d/1AbC_d-9/export?format=csv&gid=7", true, true},
		{"https://docs.google.com/spreadsheets/d/1AbC_d-9", "https://docs.google.com/spreadsheets/d/1AbC_d-9/export?format=csv", true, true},
		{"https://docs.google.com/document/d/1XyZ-0_q/edit?tab=t.0", "https://docs.google.com/document/d/1XyZ-0_q/export?format=txt", false, true},
		{"https://docs.google.com/document/d/1XyZ-0_q/edit?usp=sharing", "https://docs.google.com/document/d/1XyZ-0_q/export?format=txt", false, true},
		// Not changed: published links already work, other hosts and odd paths stay as they are.
		{"https://docs.google.com/spreadsheets/d/e/2PACX-1v/pub?output=csv", "", false, false},
		{"https://docs.google.com/document/d/e/2PACX-1v/pub", "", false, false},
		{"https://docs.google.com/spreadsheets/d/1AbC/edit?gid=abc", "", false, false},
		{"https://docs.google.com/forms/d/1AbC/edit", "", false, false},
		{"https://docs.google.com.evil.example/spreadsheets/d/1AbC/edit", "", false, false},
		{"http://docs.google.com/spreadsheets/d/1AbC/edit", "", false, false},
		{"https://example.com/spreadsheets/d/1AbC/edit", "", false, false},
	}
	for _, c := range cases {
		// Arrange
		u, err := url.Parse(c.in)
		if err != nil {
			t.Fatal(err)
		}

		// Act
		got, data, ok := GoogleExport(u)

		// Assert
		if ok != c.ok || (ok && (got.String() != c.want || data != c.data)) {
			t.Errorf("%s: got %v data=%v ok=%v, want %s data=%v ok=%v", c.in, got, data, ok, c.want, c.data, c.ok)
		}
	}
}

func TestCheckRedirect_GoogleSignInExplainsSharing(t *testing.T) {
	// Arrange
	first, _ := http.NewRequest(http.MethodGet, "https://docs.google.com/spreadsheets/d/1AbC/export?format=csv", nil)
	signIn, _ := url.Parse("https://accounts.google.com/ServiceLogin?continue=x")
	other, _ := http.NewRequest(http.MethodGet, "https://example.com/a", nil)

	// Act
	err := checkRedirect(signIn, []*http.Request{first}, false)
	elsewhere := checkRedirect(signIn, []*http.Request{other}, false)

	// Assert
	if !errors.Is(err, ErrGoogleSignIn) {
		t.Errorf("err = %v, want ErrGoogleSignIn", err)
	}
	if !errors.Is(elsewhere, ErrOffSite) {
		t.Errorf("a non-Google page redirecting to accounts.google.com: %v, want ErrOffSite", elsewhere)
	}
}
