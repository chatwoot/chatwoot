package knowledge

import (
	"strings"
	"testing"
	"unicode/utf8"
)

func TestSplit_ShortTextIsOneChunk(t *testing.T) {
	// Arrange
	text := "  ร้านเปิด 9 โมงเช้าถึง 6 โมงเย็น  \r\n"

	// Act
	got := Split(text, 100)

	// Assert
	if len(got) != 1 || got[0] != "ร้านเปิด 9 โมงเช้าถึง 6 โมงเย็น" {
		t.Errorf("got %q", got)
	}
}

func TestSplit_EmptyGivesNothing(t *testing.T) {
	// Arrange / Act
	got := Split(" \n\n ", 100)

	// Assert
	if got != nil {
		t.Errorf("got %q", got)
	}
}

func TestSplit_PacksParagraphsUpToLimit(t *testing.T) {
	// Arrange: three 10-rune paragraphs; two fit in 25 runes with the separator.
	p := strings.Repeat("ก", 10)
	text := p + "\n\n" + p + "\n\n" + p

	// Act
	got := Split(text, 25)

	// Assert
	if len(got) != 2 || got[0] != p+"\n\n"+p || got[1] != p {
		t.Errorf("got %q", got)
	}
}

func TestSplit_ThaiSentencesSplitAtSpaces(t *testing.T) {
	// Arrange: one long Thai line, sentences separated by single spaces.
	s1, s2, s3 := "ส่งสินค้าทุกวันจันทร์ถึงศุกร์", "ค่าส่งฟรีเมื่อซื้อครบห้าร้อยบาท", "คืนสินค้าได้ภายในเจ็ดวัน"
	text := s1 + " " + s2 + " " + s3

	// Act
	got := Split(text, 40)

	// Assert
	if strings.Join(got, " ") != text {
		t.Errorf("content lost or reordered: %q", got)
	}
	for _, c := range got {
		if utf8.RuneCountInString(c) > 40 {
			t.Errorf("chunk over limit: %q", c)
		}
	}
	if len(got) < 2 {
		t.Errorf("expected a split, got %q", got)
	}
}

func TestSplit_NoSeparatorIsCutByLength(t *testing.T) {
	// Arrange
	text := strings.Repeat("ข", 95)

	// Act
	got := Split(text, 40)

	// Assert
	if len(got) != 3 || strings.Join(got, "") != text {
		t.Errorf("got %d chunks", len(got))
	}
	for _, c := range got {
		if utf8.RuneCountInString(c) > 40 {
			t.Errorf("chunk over limit: %d runes", utf8.RuneCountInString(c))
		}
	}
}

func TestSections_SplitsAtMarkdownHeadings(t *testing.T) {
	// Arrange
	text := "intro line\n\n# Menu\n## Coffee\nlatte 70\n\n## Tea\nthai tea 60\n#hashtag is not a heading"

	// Act
	got := Sections(text)

	// Assert
	want := []Section{{"", "intro line"}, {"Coffee", "latte 70"}, {"Tea", "thai tea 60\n#hashtag is not a heading"}}
	if len(got) != len(want) {
		t.Fatalf("got %+v", got)
	}
	for i := range want {
		if got[i] != want[i] {
			t.Errorf("section %d = %+v, want %+v", i, got[i], want[i])
		}
	}
}

func TestFirstHeading(t *testing.T) {
	// Arrange / Act / Assert
	if h := FirstHeading("\n# เมนูและราคา\n\ntext"); h != "เมนูและราคา" {
		t.Errorf("got %q", h)
	}
	if h := FirstHeading("no heading here"); h != "" {
		t.Errorf("got %q", h)
	}
}
