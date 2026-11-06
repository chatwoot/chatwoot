package knowledge

import (
	"strings"
	"unicode/utf8"
)

// separators are tried from coarse to fine: paragraphs, lines, spaces.
// Thai has no spaces between words but does put a space between sentences,
// so the space level splits Thai at sentence boundaries. Text with no
// separator at all is cut by length as a last resort.
var separators = []string{"\n\n", "\n", " "}

// Split cuts text into chunks of at most maxRunes runes, keeping paragraphs
// and sentences together where possible. Empty input gives no chunks.
func Split(text string, maxRunes int) []string {
	text = strings.TrimSpace(strings.ReplaceAll(text, "\r\n", "\n"))
	if text == "" || maxRunes < 1 {
		return nil
	}
	return split(text, maxRunes, 0)
}

func split(text string, maxRunes, level int) []string {
	if utf8.RuneCountInString(text) <= maxRunes {
		return []string{text}
	}
	if level == len(separators) {
		return hardCut(text, maxRunes)
	}
	sep := separators[level]
	var out []string
	cur := ""
	flush := func() {
		if cur != "" {
			out = append(out, cur)
			cur = ""
		}
	}
	for _, part := range strings.Split(text, sep) {
		part = strings.TrimSpace(part)
		if part == "" {
			continue
		}
		switch {
		case utf8.RuneCountInString(part) > maxRunes:
			flush()
			out = append(out, split(part, maxRunes, level+1)...)
		case cur == "":
			cur = part
		case utf8.RuneCountInString(cur)+utf8.RuneCountInString(sep)+utf8.RuneCountInString(part) <= maxRunes:
			cur += sep + part
		default:
			flush()
			cur = part
		}
	}
	flush()
	return out
}

func hardCut(text string, maxRunes int) []string {
	r := []rune(text)
	var out []string
	for len(r) > 0 {
		n := min(maxRunes, len(r))
		out = append(out, string(r[:n]))
		r = r[n:]
	}
	return out
}

// Section is a part of a Markdown document under its nearest heading.
type Section struct {
	Heading string // "" for text before the first heading
	Body    string
}

// headingText returns the text of an ATX Markdown heading line ("## Tea"),
// or "" if the line is not a heading. "#tag" (no space) is not a heading.
func headingText(line string) string {
	t := strings.TrimSpace(line)
	n := 0
	for n < len(t) && n < 6 && t[n] == '#' {
		n++
	}
	if n == 0 || n >= len(t) || (t[n] != ' ' && t[n] != '\t') {
		return ""
	}
	return strings.TrimSpace(strings.TrimRight(t[n:], "# "))
}

// Sections splits Markdown at its headings so each topic is embedded on its
// own instead of being blurred into one long chunk. Empty sections are dropped.
func Sections(text string) []Section {
	var out []Section
	cur := Section{}
	var body []string
	flush := func() {
		cur.Body = strings.TrimSpace(strings.Join(body, "\n"))
		if cur.Body != "" {
			out = append(out, cur)
		}
		body = nil
	}
	for _, line := range strings.Split(strings.ReplaceAll(text, "\r\n", "\n"), "\n") {
		if h := headingText(line); h != "" {
			flush()
			cur = Section{Heading: h}
			continue
		}
		body = append(body, line)
	}
	flush()
	return out
}

// FirstHeading returns the first Markdown heading, or "".
func FirstHeading(text string) string {
	for _, line := range strings.Split(text, "\n") {
		if h := headingText(line); h != "" {
			return h
		}
	}
	return ""
}
