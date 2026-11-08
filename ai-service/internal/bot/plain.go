package bot

import (
	"regexp"
	"strings"
)

// Chat apps (Messenger, LINE, Instagram) show markdown as raw symbols, so
// replies are sent as plain text whatever the model wrote.
var (
	mdBold    = regexp.MustCompile(`\*\*([^*\n]+)\*\*|__([^_\n]+)__`)
	mdLink    = regexp.MustCompile(`\[([^\]\n]+)\]\((https?://[^)\s]+)\)`)
	mdHeading = regexp.MustCompile(`(?m)^[ \t]{0,3}#{1,6}[ \t]+`)
)

// plainChat removes bold, headings and markdown links (keeping the link's
// text and its address) and swaps the Arabic question mark some models slip
// into Thai text for a plain one.
func plainChat(s string) string {
	s = mdLink.ReplaceAllStringFunc(s, func(m string) string {
		p := mdLink.FindStringSubmatch(m)
		if strings.TrimSpace(p[1]) == p[2] {
			return p[2]
		}
		return p[1] + " " + p[2]
	})
	s = mdBold.ReplaceAllString(s, "$1$2")
	s = mdHeading.ReplaceAllString(s, "")
	return strings.ReplaceAll(s, "؟", "?")
}
