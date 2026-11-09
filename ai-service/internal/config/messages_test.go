package config

import (
	"strings"
	"testing"
)

func TestDefaultMessages_HandOffToTheTeamNotASpecialist(t *testing.T) {
	for name, msg := range map[string]string{
		"handoff": DefaultHandoffMessage, "attachment": DefaultAttachmentMessage, "failure": DefaultFailureMessage,
	} {
		// Arrange / Act
		hasTeam := strings.Contains(msg, "ทีมงาน")

		// Assert
		if strings.Contains(msg, "โดยเฉพาะ") || !hasTeam {
			t.Errorf("%s message must name the team (ทีมงาน), not a specialist: %q", name, msg)
		}
		if !strings.Contains(msg, "ครับ") {
			t.Errorf("%s message lost the page's ครับ: %q", name, msg)
		}
	}
}
