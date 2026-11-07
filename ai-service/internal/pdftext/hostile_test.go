package pdftext

import (
	"bytes"
	"compress/zlib"
	"context"
	"fmt"
	"strings"
	"testing"
	"time"
)

// buildPDF writes a PDF with a correct cross-reference table from numbered
// object bodies (object 1 is the catalog).
func buildPDF(objs []string) []byte {
	var b bytes.Buffer
	b.WriteString("%PDF-1.4\n")
	offs := make([]int, len(objs))
	for i, o := range objs {
		offs[i] = b.Len()
		fmt.Fprintf(&b, "%d 0 obj\n%s\nendobj\n", i+1, o)
	}
	xref := b.Len()
	fmt.Fprintf(&b, "xref\n0 %d\n0000000000 65535 f \n", len(objs)+1)
	for _, o := range offs {
		fmt.Fprintf(&b, "%010d 00000 n \n", o)
	}
	fmt.Fprintf(&b, "trailer\n<< /Size %d /Root 1 0 R >>\nstartxref\n%d\n%%%%EOF\n", len(objs)+1, xref)
	return b.Bytes()
}

func stream(dict string, data []byte) string {
	return fmt.Sprintf("<< %s /Length %d >>\nstream\n%s\nendstream", dict, len(data), data)
}

// deflate compresses n bytes of repeat into a small stream (a "bomb").
func deflate(repeat string, n int) []byte {
	var b bytes.Buffer
	w, _ := zlib.NewWriterLevel(&b, zlib.BestCompression)
	chunk := []byte(strings.Repeat(repeat, 1<<16/len(repeat)))
	for written := 0; written < n; written += len(chunk) {
		_, _ = w.Write(chunk)
	}
	_ = w.Close()
	return b.Bytes()
}

const font = "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>"

func TestExtract_HostileFilesNeverHurtTheService(t *testing.T) {
	old := Timeout
	Timeout = 3 * time.Second
	defer func() { Timeout = old }()
	cases := map[string][]byte{
		// The page tree points back at itself: the parser loops forever.
		"cyclic page tree": buildPDF([]string{
			"<< /Type /Catalog /Pages 2 0 R >>",
			"<< /Type /Pages /Kids [2 0 R] /Count 5 >>",
		}),
		// A page that is its own parent, with no resources to find.
		"page is its own parent": buildPDF([]string{
			"<< /Type /Catalog /Pages 2 0 R >>",
			"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
			"<< /Type /Page /Parent 3 0 R /Contents 4 0 R >>",
			stream("", []byte("BT (Hi) Tj ET")),
		}),
		// 1 GB of text drawing behind about a megabyte of compressed data.
		"compression bomb": buildPDF([]string{
			"<< /Type /Catalog /Pages 2 0 R >>",
			"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
			"<< /Type /Page /Parent 2 0 R /Resources << /Font << /F1 5 0 R >> >> /Contents 4 0 R >>",
			stream("/Filter /FlateDecode", deflate("BT /F1 12 Tf (AAAAAAAAAAAAAAAA) Tj ET\n", 1<<30)),
			font,
		}),
		// Millions of operands with no operator pile up on the parser's stack.
		"operand flood": buildPDF([]string{
			"<< /Type /Catalog /Pages 2 0 R >>",
			"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
			"<< /Type /Page /Parent 2 0 R /Resources << /Font << /F1 5 0 R >> >> /Contents 4 0 R >>",
			stream("/Filter /FlateDecode", deflate("1 ", 600<<20)),
			font,
		}),
	}
	for name, pdf := range cases {
		t.Run(name, func(t *testing.T) {
			// Act
			start := time.Now()
			res, err := Extract(context.Background(), pdf)

			// Assert: an error or harmless text, within the time limit, and
			// this process (the service) is still running to check it.
			if took := time.Since(start); took > Timeout+5*time.Second {
				t.Errorf("took %v", took)
			}
			if err == nil && len(res.Text) > 8*MaxRunes {
				t.Errorf("text of %d bytes passed the limits", len(res.Text))
			}
			t.Logf("%d bytes in, err=%v, pages=%d, took=%v", len(pdf), err, res.Pages, time.Since(start).Round(time.Millisecond))
		})
	}
}

func TestExtract_OnePDFAtATime(t *testing.T) {
	// Arrange: hold the slot as a running read would.
	slot <- struct{}{}
	defer func() { <-slot }()

	// Act
	_, err := Extract(context.Background(), load(t, "thai.pdf"))

	// Assert
	if err != ErrBusy {
		t.Errorf("err = %v, want ErrBusy", err)
	}
}

func TestExtract_ChildGetsNoSecrets(t *testing.T) {
	// Arrange
	t.Setenv("OPENAI_API_KEY", "sk-test-should-not-pass")
	t.Setenv("ADMIN_PASSWORD", "nope")

	// Act
	env := childEnviron()

	// Assert
	for _, kv := range env {
		if strings.Contains(kv, "sk-test") || strings.HasPrefix(kv, "ADMIN_PASSWORD") {
			t.Errorf("secret passed to the child: %s", strings.SplitN(kv, "=", 2)[0])
		}
	}
}
