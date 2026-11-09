// Package brand holds the Pronto logo for the pages ai-service serves itself
// (/admin and the OAuth consent page). DEV-Johnstocker/chatwoot#1.
//
// logo.svg and logo_thumbnail.svg are copies of deploy/branding/, which
// brands Chatwoot; a test keeps the two in step.
package brand

import (
	"embed"
	"encoding/base64"
	"html/template"
	"strings"
)

//go:embed logo.svg logo_thumbnail.svg
var files embed.FS

// Wordmark is the Pronto wordmark as an inline <svg>. It is drawn in
// currentColor, so the page's CSS picks the light or dark colour, and being
// inline it needs no image source in the Content-Security-Policy.
var Wordmark = template.HTML(wordmark(mustRead("logo.svg")))

// FaviconURL is the "p" mark as a data: URI for <link rel="icon">. Pages
// that use it need img-src data: in their Content-Security-Policy.
var FaviconURL = template.URL("data:image/svg+xml;base64," + base64.StdEncoding.EncodeToString([]byte(mustRead("logo_thumbnail.svg"))))

func mustRead(name string) string {
	b, err := files.ReadFile(name)
	if err != nil {
		panic(err) // embedded at build time; cannot fail at run time
	}
	return string(b)
}

// wordmark turns the logo file into an accessible, theme-coloured inline svg.
func wordmark(svg string) string {
	svg = strings.Replace(svg, "<svg ", `<svg class="logo" role="img" aria-label="Pronto" focusable="false" `, 1)
	return strings.ReplaceAll(svg, `fill="#3300aa"`, `fill="currentColor"`)
}
