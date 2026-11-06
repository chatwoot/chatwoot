package handoff

import (
	"testing"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/config"
)

func TestWants_DefaultKeywords(t *testing.T) {
	d := New(config.DefaultHandoffKeywords)
	cases := []struct {
		text string
		want bool
	}{
		{"ขอคุยกับแอดมินหน่อยค่ะ", true},
		{"อยากคุยกับคนจริงๆ", true},
		{"ຂໍລົມກັບຄົນແດ່", true},
		{"Can I talk to a HUMAN please?", true},
		{"ราคาเท่าไหร่คะ", false},
		{"what are your opening hours", false},
	}
	for _, tc := range cases {
		t.Run(tc.text, func(t *testing.T) {
			// Arrange: detector built above

			// Act
			got := d.Wants(tc.text)

			// Assert
			if got != tc.want {
				t.Errorf("Wants(%q) = %v, want %v", tc.text, got, tc.want)
			}
		})
	}
}

func TestNew_SkipsBlankKeywords(t *testing.T) {
	// Arrange
	d := New([]string{"", "  "})

	// Act
	got := d.Wants("anything")

	// Assert
	if got {
		t.Error("blank keywords must not match everything")
	}
}
