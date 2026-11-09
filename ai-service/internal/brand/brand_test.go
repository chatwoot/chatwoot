package brand

import (
	"encoding/base64"
	"os"
	"strings"
	"testing"
)

func TestFilesMatchDeployBranding(t *testing.T) {
	for _, name := range []string{"logo.svg", "logo_thumbnail.svg"} {
		// Arrange
		want, err := os.ReadFile("../../deploy/branding/" + name)
		if err != nil {
			t.Fatal(err)
		}

		// Act
		got, err := files.ReadFile(name)

		// Assert
		if err != nil || string(got) != string(want) {
			t.Errorf("%s differs from deploy/branding/%s; copy it again", name, name)
		}
	}
}

func TestWordmark_InlineThemeColouredAndLabelled(t *testing.T) {
	// Arrange
	w := string(Wordmark)

	// Act
	start := w[:strings.Index(w, ">")]

	// Assert
	if !strings.HasPrefix(w, "<svg") || !strings.HasSuffix(strings.TrimSpace(w), "</svg>") {
		t.Fatal("wordmark is not one svg element")
	}
	for _, want := range []string{`role="img"`, `aria-label="Pronto"`, `class="logo"`} {
		if !strings.Contains(start, want) {
			t.Errorf("svg tag missing %s", want)
		}
	}
	if !strings.Contains(w, `fill="currentColor"`) || strings.Contains(strings.ToLower(w), "#3300aa") {
		t.Error("wordmark must take its colour from CSS (currentColor), not a fixed fill")
	}
	if strings.Contains(strings.ToLower(w), "<script") || strings.Contains(strings.ToLower(w), "href") {
		t.Error("wordmark must carry no script or links")
	}
}

func TestFaviconURL_IsTheThumbnailAsDataURI(t *testing.T) {
	// Arrange
	const prefix = "data:image/svg+xml;base64,"
	want, _ := files.ReadFile("logo_thumbnail.svg")

	// Act
	u := string(FaviconURL)
	got, err := base64.StdEncoding.DecodeString(strings.TrimPrefix(u, prefix))

	// Assert
	if !strings.HasPrefix(u, prefix) || err != nil || string(got) != string(want) {
		t.Fatalf("favicon is not the thumbnail as a data URI (err=%v)", err)
	}
}
