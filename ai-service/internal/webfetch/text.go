package webfetch

import (
	"bytes"
	"regexp"
	"strings"
	"unicode"

	"golang.org/x/net/html"
	"golang.org/x/net/html/atom"
)

// skip are elements whose text is never page content.
var skip = map[atom.Atom]bool{
	atom.Script: true, atom.Style: true, atom.Noscript: true, atom.Template: true, atom.Svg: true,
	atom.Nav: true, atom.Header: true, atom.Footer: true, atom.Form: true, atom.Iframe: true,
	atom.Button: true, atom.Select: true, atom.Aside: true,
}

var blockLevel = map[atom.Atom]bool{
	atom.P: true, atom.Div: true, atom.Section: true, atom.Article: true, atom.Main: true, atom.Br: true,
	atom.Tr: true, atom.Table: true, atom.Ul: true, atom.Ol: true, atom.Blockquote: true, atom.Pre: true,
	atom.Dl: true, atom.Dt: true, atom.Dd: true, atom.Figure: true, atom.Figcaption: true,
}

var headings = map[atom.Atom]string{atom.H1: "# ", atom.H2: "## ", atom.H3: "### ", atom.H4: "#### ", atom.H5: "##### ", atom.H6: "###### "}

var blankLines = regexp.MustCompile(`\n{3,}`)

// Text turns a page into Markdown-like text for the knowledge base: headings
// stay as # sections (so long pages split by section), list items as "- ",
// table cells separated by " | ". The title is the first <h1>, else <title>.
func Text(p Page) (title, text string) {
	if p.ContentType != "text/html" {
		return "", strings.TrimSpace(string(p.Body))
	}
	doc, err := html.Parse(bytes.NewReader(p.Body))
	if err != nil {
		return "", ""
	}
	var b strings.Builder
	var h1 string
	var walk func(n *html.Node)
	walk = func(n *html.Node) {
		if n.Type == html.ElementNode {
			if skip[n.DataAtom] || hidden(n) {
				return
			}
			if n.DataAtom == atom.Title && title == "" && n.FirstChild != nil {
				title = clean(n.FirstChild.Data)
				return
			}
			if n.DataAtom == atom.Head {
				for c := n.FirstChild; c != nil; c = c.NextSibling {
					walk(c)
				}
				return
			}
			if h, ok := headings[n.DataAtom]; ok {
				text := clean(inner(n))
				if n.DataAtom == atom.H1 && h1 == "" {
					h1 = text
				}
				b.WriteString("\n\n" + h + text + "\n\n")
				return
			}
			switch n.DataAtom {
			case atom.Li:
				b.WriteString("\n- ")
			case atom.Td, atom.Th:
				b.WriteString(" | ")
			}
			if blockLevel[n.DataAtom] {
				b.WriteString("\n")
			}
		}
		if n.Type == html.TextNode {
			if t := clean(n.Data); t != "" {
				b.WriteString(t + " ")
			}
		}
		for c := n.FirstChild; c != nil; c = c.NextSibling {
			walk(c)
		}
		if n.Type == html.ElementNode && blockLevel[n.DataAtom] {
			b.WriteString("\n")
		}
	}
	walk(doc)
	if h1 != "" {
		title = h1 // a site-wide <title> says less than the page's own heading
	}
	lines := strings.Split(b.String(), "\n")
	for i, l := range lines {
		lines[i] = strings.Join(strings.Fields(l), " ")
	}
	return title, strings.TrimSpace(blankLines.ReplaceAllString(strings.Join(lines, "\n"), "\n\n"))
}

func hidden(n *html.Node) bool {
	streamed := false // React streaming SSR sends content in <div hidden id="S:n"> and swaps it in
	for _, a := range n.Attr {
		if a.Key == "id" && strings.HasPrefix(a.Val, "S:") {
			streamed = true
		}
	}
	for _, a := range n.Attr {
		switch {
		case a.Key == "hidden" && streamed:
			continue
		case a.Key == "role" && (a.Val == "status" || a.Val == "progressbar" || a.Val == "alert"):
			return true // loading spinners and toasts, not page content
		case a.Key == "hidden", a.Key == "aria-hidden" && a.Val == "true":
			return true
		case a.Key == "style" && strings.Contains(strings.ReplaceAll(strings.ToLower(a.Val), " ", ""), "display:none"):
			return true
		}
	}
	return false
}

func inner(n *html.Node) string {
	var b strings.Builder
	var walk func(*html.Node)
	walk = func(n *html.Node) {
		if n.Type == html.TextNode {
			b.WriteString(n.Data + " ")
		}
		for c := n.FirstChild; c != nil; c = c.NextSibling {
			walk(c)
		}
	}
	walk(n)
	return b.String()
}

// clean collapses whitespace and drops control characters.
func clean(s string) string {
	s = strings.Map(func(r rune) rune {
		if unicode.IsControl(r) && r != '\n' && r != '\t' {
			return -1
		}
		return r
	}, s)
	return strings.Join(strings.Fields(s), " ")
}
