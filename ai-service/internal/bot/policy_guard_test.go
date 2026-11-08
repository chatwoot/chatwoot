package bot

import (
	"strings"
	"testing"
	"time"
)

func TestPolicy_ForbidsCollectingSecretsInChat(t *testing.T) {
	// Arrange
	now := time.Date(2026, 11, 8, 3, 0, 0, 0, time.UTC)

	// Act
	p := policyPrompt(now)

	// Assert
	for _, want := range []string{"card numbers", "CVV", "OTP", "passwords", "ID card numbers", "hand off"} {
		if !strings.Contains(p, want) {
			t.Errorf("policy is missing %q", want)
		}
	}
	if !strings.Contains(p, "even if the business profile") {
		t.Error("policy does not say the profile cannot lift the rule")
	}
}
