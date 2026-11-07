package pdftext

import (
	"context"
	"errors"
	"os"
	"strings"
	"testing"
	"time"
)

var _ = time.Second

func load(t *testing.T, name string) []byte {
	t.Helper()
	b, err := os.ReadFile("testdata/" + name)
	if err != nil {
		t.Fatal(err)
	}
	return b
}

func TestExtract_ThaiAndEnglishWithTable(t *testing.T) {
	// Arrange: made by Chromium (Tahoma), two pages, a table.
	b := load(t, "thai.pdf")

	// Act
	res, err := Extract(context.Background(), b)

	// Assert
	if err != nil {
		t.Fatal(err)
	}
	if res.Pages != 2 {
		t.Errorf("pages = %d, want 2", res.Pages)
	}
	for _, want := range []string{
		"นโยบายการคืนเงิน (Refund Policy)",
		"John Auto Cut costs 3,900 baht for lifetime access.",
		"3,900 บาท",
		"LINE Official @johnstocker",
		"บนคอมพิวเตอร์ของผู้เรียนเอง", // tone marks kept where the PDF maps them (ผู้)
	} {
		if !strings.Contains(res.Text, want) {
			t.Errorf("text missing %q", want)
		}
	}
	// Where the PDF maps a tone mark to nothing, no stray space is left inside the word.
	for _, bad := range []string{"เนื อหา", "ที ระบบ", "ชั วโมง", "\x00"} {
		if strings.Contains(res.Text, bad) {
			t.Errorf("text contains %q", bad)
		}
	}
}

func TestExtract_PagesSeparated(t *testing.T) {
	// Arrange
	b := load(t, "english3.pdf")

	// Act
	res, err := Extract(context.Background(), b)

	// Assert
	if err != nil || res.Pages != 3 {
		t.Fatalf("res=%+v err=%v", res, err)
	}
	if strings.Index(res.Text, "Price list") > strings.Index(res.Text, "Page three") ||
		!strings.Contains(res.Text, "not refundable") {
		t.Errorf("text = %q", res.Text)
	}
}

func TestExtract_RefusesWhatHasNoText(t *testing.T) {
	// Arrange
	cases := map[string][]byte{
		"drawing only (like a scan)": load(t, "notext.pdf"),
		"not a PDF":                  []byte("hello, this is plain text"),
		"empty":                      nil,
		"truncated PDF":              load(t, "thai.pdf")[:4000],
	}
	for name, b := range cases {
		// Act
		_, err := Extract(context.Background(), b)

		// Assert
		if err == nil {
			t.Errorf("%s: no error", name)
		}
	}
	if _, err := Extract(context.Background(), load(t, "notext.pdf")); !errors.Is(err, ErrNoText) {
		t.Errorf("drawing-only PDF: err = %v, want ErrNoText", err)
	}
}

func TestExtract_LimitsSize(t *testing.T) {
	// Arrange
	big := make([]byte, MaxBytes+1)
	copy(big, "%PDF-1.4")

	// Act
	_, err := Extract(context.Background(), big)

	// Assert
	if !errors.Is(err, ErrTooLarge) {
		t.Errorf("err = %v, want ErrTooLarge", err)
	}
}

func TestFixThai(t *testing.T) {
	cases := map[string]string{
		"เนื อหา":                      "เนือหา",
		"ที ระบบ":                      "ทีระบบ",
		"มี ปัญหา ไหม":                 "มีปัญหา ไหม", // a space after an upper vowel is dropped; others stay
		"Price list  3,900\n\n\n\nบาท": "Price list 3,900\n\nบาท",
		"a\x00b":                       "ab",
		"   leading and trailing   ":   "leading and trailing",
		"ภาษาไทย ธรรมดา English words ok": "ภาษาไทย ธรรมดา English words ok",
	}
	for in, want := range cases {
		if got := normalize(in); got != want {
			t.Errorf("normalize(%q) = %q, want %q", in, got, want)
		}
	}
}

// FuzzExtract: malformed PDFs must return an error, never crash the service.
func FuzzExtract(f *testing.F) {
	for _, name := range []string{"thai.pdf", "english3.pdf", "notext.pdf"} {
		b, err := os.ReadFile("testdata/" + name)
		if err != nil {
			f.Fatal(err)
		}
		f.Add(b)
	}
	f.Fuzz(func(t *testing.T, b []byte) {
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()
		res, err := Extract(ctx, b)
		if err == nil && strings.ContainsRune(res.Text, 0) {
			t.Error("NUL in text")
		}
	})
}
