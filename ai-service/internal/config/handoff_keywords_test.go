package config

import (
	"testing"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/handoff"
)

func TestDefaultHandoffKeywordsMatchRequestsNotMentions(t *testing.T) {
	// Arrange
	d := handoff.New(DefaultHandoffKeywords)
	requests := []string{"ขอคุยกับแอดมินหน่อย", "ขอคุยกับพนักงานค่ะ", "ติดต่อเจ้าหน้าที่ได้ไหม", "อยากคุยกับคน",
		"ขอเจ้าหน้าที่หน่อย", "ລົມກັບພະນັກງານ", "I want to talk to a person"}
	mentions := []string{"บริษัทมีพนักงานกี่คน", "เจ้าหน้าที่จะส่งอีเมลเข้าเรียนเมื่อไหร่", "พนักงานใช้ AutoCut ได้ไหม", "ພະນັກງານມີຈັກຄົນ"}

	// Act + Assert
	for _, text := range requests {
		if !d.Wants(text) {
			t.Errorf("Wants(%q) = false, want a handoff", text)
		}
	}
	for _, text := range mentions {
		if d.Wants(text) {
			t.Errorf("Wants(%q) = true, a mention of staff is not a request for one", text)
		}
	}
}
