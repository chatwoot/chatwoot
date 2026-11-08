package intake

import (
	"strings"
	"testing"
)

func TestSplitText_ByHeadingThenParagraph(t *testing.T) {
	// Arrange
	text := "# AutoCut Pro\nราคา 3,900 บาท\n\nใช้ได้ 1 เครื่อง\n\n## วิธีติดตั้ง\nดาวน์โหลดแล้วกด Next\n\n\n"

	// Act
	got := SplitText(text)

	// Assert
	if len(got) != 2 || got[0].Title != "AutoCut Pro" || !strings.Contains(got[0].Content, "1 เครื่อง") || got[1].Title != "วิธีติดตั้ง" {
		t.Fatalf("SplitText = %+v", got)
	}
}

func TestSplitText_NoHeadingsUsesParagraphs(t *testing.T) {
	// Arrange
	text := "ราคา 3,900 บาท\n\nติดตั้งบน Windows 10 ได้\n\n  \n"

	// Act
	got := SplitText(text)

	// Assert
	if len(got) != 2 || got[0].Title != "ราคา 3,900 บาท" || got[1].Content != "ติดตั้งบน Windows 10 ได้" {
		t.Fatalf("SplitText = %+v", got)
	}
}

func TestSplitText_LongSectionIsCut(t *testing.T) {
	// Arrange
	para := strings.Repeat("ก", 1500)
	text := "# Long\n" + para + "\n\n" + para + "\n\n" + para

	// Act
	got := SplitText(text)

	// Assert
	for _, p := range got {
		if n := len([]rune(p.Content)); n > MaxPieceRunes {
			t.Fatalf("piece of %d runes, limit %d", n, MaxPieceRunes)
		}
		if p.Title != "Long" {
			t.Fatalf("cut piece lost its heading: %q", p.Title)
		}
	}
	if len(got) < 2 {
		t.Fatalf("long section not cut: %d pieces", len(got))
	}
}
