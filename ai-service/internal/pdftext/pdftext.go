// Package pdftext reads the text out of a PDF for the knowledge base, using
// github.com/ledongthuc/pdf (BSD-3-Clause, pure Go, no dependencies).
//
// PDFs keep positioned glyphs, not text: the result is as good as the file's
// character map. Some PDF makers map Thai tone marks that sit above another
// vowel to nothing; those marks cannot be recovered, and the stray space they
// leave inside a word is removed. A scanned PDF (images only) has no text.
package pdftext

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"regexp"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/ledongthuc/pdf"
)

// Limits.
const (
	MaxBytes = 10 << 20
	MaxPages = 300
	MaxRunes = 200_000 // knowledge.MaxContentRunes
	Timeout  = 30 * time.Second
)

// Errors shown to the owner.
var (
	ErrTooLarge   = fmt.Errorf("the PDF is larger than %d MB", MaxBytes>>20)
	ErrNoText     = errors.New("no text found in the PDF; it may be a scan or made of images (export it with text, or paste the text instead)")
	ErrEncrypted  = errors.New("the PDF is password-protected; save a copy without a password and upload that")
	ErrUnreadable = errors.New("the file could not be read as a PDF")
	ErrTimeout    = errors.New("reading the PDF took too long; try a smaller file")
)

// Result is the text of a PDF.
type Result struct {
	Text      string
	Pages     int  // pages read
	Truncated bool // more than MaxPages pages, or more than MaxRunes characters
}

// Extract reads up to MaxPages pages. A broken or hostile file returns an
// error rather than crashing, and reading stops after Timeout.
func Extract(ctx context.Context, b []byte) (Result, error) {
	switch {
	case len(b) > MaxBytes:
		return Result{}, ErrTooLarge
	case !bytes.HasPrefix(bytes.TrimLeft(b, " \t\r\n"), []byte("%PDF-")):
		return Result{}, ErrUnreadable
	}
	ctx, cancel := context.WithTimeout(ctx, Timeout)
	defer cancel()
	type out struct {
		res Result
		err error
	}
	done := make(chan out, 1)
	go func() {
		res, err := extract(b)
		done <- out{res, err}
	}()
	select {
	case o := <-done:
		return o.res, o.err
	case <-ctx.Done():
		// The reader cannot be interrupted; its goroutine ends with the file.
		return Result{}, ErrTimeout
	}
}

func extract(b []byte) (res Result, err error) {
	defer func() {
		if r := recover(); r != nil { // the parser panics on some malformed files
			res, err = Result{}, ErrUnreadable
		}
	}()
	r, err := pdf.NewReader(bytes.NewReader(b), int64(len(b)))
	if err != nil {
		if strings.Contains(strings.ToLower(err.Error()), "encrypt") || strings.Contains(strings.ToLower(err.Error()), "password") {
			return Result{}, ErrEncrypted
		}
		return Result{}, ErrUnreadable
	}
	n := r.NumPage()
	if n > MaxPages {
		n, res.Truncated = MaxPages, true
	}
	var sb strings.Builder
	fonts := map[string]*pdf.Font{}
	for i := 1; i <= n; i++ {
		p := r.Page(i)
		if p.V.IsNull() {
			continue
		}
		for _, name := range p.Fonts() {
			if _, ok := fonts[name]; !ok {
				f := p.Font(name)
				fonts[name] = &f
			}
		}
		text, err := p.GetPlainText(fonts)
		if err != nil {
			continue // one bad page should not lose the others
		}
		sb.WriteString(text)
		sb.WriteString("\n\n")
		res.Pages++
		if sb.Len() > 4*MaxRunes {
			res.Truncated = true
			break
		}
	}
	text := normalize(sb.String())
	if utf8.RuneCountInString(text) > MaxRunes {
		text, res.Truncated = string([]rune(text)[:MaxRunes]), true
	}
	if strings.TrimSpace(text) == "" {
		return Result{}, ErrNoText
	}
	res.Text = text
	return res, nil
}

var (
	// A space right after a Thai upper vowel and before a Thai letter is the
	// trace of a tone mark the PDF did not map (เนื อหา → เนือหา).
	thaiGap    = regexp.MustCompile(`([\x{0E31}\x{0E34}-\x{0E37}\x{0E47}]) ([\x{0E01}-\x{0E4E}])`)
	spaceRuns  = regexp.MustCompile(`[ \t\x{00A0}]+`)
	blankLines = regexp.MustCompile(`\n[ \t]*\n(?:[ \t]*\n)+`)
)

// normalize cleans extracted text: no NULs, single spaces, at most one blank
// line in a row, and Thai words rejoined where a lost tone mark split them.
func normalize(s string) string {
	s = strings.ReplaceAll(s, "\x00", "")
	s = strings.ReplaceAll(s, "\r\n", "\n")
	s = spaceRuns.ReplaceAllString(s, " ")
	s = thaiGap.ReplaceAllString(s, "$1$2")
	s = blankLines.ReplaceAllString(s, "\n\n")
	lines := strings.Split(s, "\n")
	for i, l := range lines {
		lines[i] = strings.TrimSpace(l)
	}
	return strings.TrimSpace(strings.Join(lines, "\n"))
}
