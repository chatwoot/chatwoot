package intake

import (
	"regexp"
	"strings"
)

// MaxPieceRunes caps one piece; longer sections are cut at paragraphs.
const MaxPieceRunes = 2000

const maxTitleRunes = 80

var heading = regexp.MustCompile(`^[ \t]{0,3}#{1,6}[ \t]+(.+?)[ \t#]*$`)

// SplitText cuts free text into pieces: one per Markdown heading section, or
// one per paragraph when there are no headings. Long sections are cut at
// paragraph breaks and keep their heading as the title.
func SplitText(text string) []Piece {
	text = strings.ReplaceAll(text, "\r\n", "\n")
	type section struct {
		title string
		paras []string
	}
	var secs []section
	var cur *section
	var para []string
	flush := func() {
		if p := strings.TrimSpace(strings.Join(para, "\n")); p != "" {
			if cur == nil {
				secs = append(secs, section{})
				cur = &secs[len(secs)-1]
			}
			cur.paras = append(cur.paras, p)
		}
		para = nil
	}
	headed := false
	for _, line := range strings.Split(text, "\n") {
		if m := heading.FindStringSubmatch(line); m != nil {
			flush()
			secs = append(secs, section{title: strings.TrimSpace(m[1])})
			cur, headed = &secs[len(secs)-1], true
			continue
		}
		if strings.TrimSpace(line) == "" {
			flush()
			continue
		}
		para = append(para, line)
	}
	flush()

	var out []Piece
	for _, s := range secs {
		if !headed || s.title == "" {
			for _, p := range s.paras {
				for _, c := range pack([]string{p}) {
					out = append(out, Piece{Title: firstLine(c), Content: c})
				}
			}
			continue
		}
		for _, c := range pack(s.paras) {
			out = append(out, Piece{Title: s.title, Content: c})
		}
	}
	return out
}

// pack joins paragraphs into chunks of at most MaxPieceRunes.
func pack(paras []string) []string {
	var out []string
	var b []rune
	for _, p := range paras {
		r := []rune(p)
		for len(r) > MaxPieceRunes { // one paragraph too long on its own
			if len(b) > 0 {
				out, b = append(out, string(b)), nil
			}
			out, r = append(out, string(r[:MaxPieceRunes])), r[MaxPieceRunes:]
		}
		if len(b) > 0 && len(b)+2+len(r) > MaxPieceRunes {
			out, b = append(out, string(b)), nil
		}
		if len(b) > 0 {
			b = append(b, '\n', '\n')
		}
		b = append(b, r...)
	}
	if len(b) > 0 {
		out = append(out, string(b))
	}
	return out
}

func firstLine(s string) string {
	line, _, _ := strings.Cut(s, "\n")
	if r := []rune(strings.TrimSpace(line)); len(r) > maxTitleRunes {
		return string(r[:maxTitleRunes])
	}
	return strings.TrimSpace(line)
}
