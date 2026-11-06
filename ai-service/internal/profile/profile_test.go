package profile

import (
	"strings"
	"testing"
)

func TestPromptWithoutProfileReturnsBase(t *testing.T) {
	// Arrange
	base := "You are a support assistant."

	// Act
	got := Prompt(base, Profile{AccountID: 1})

	// Assert
	if got != base {
		t.Fatalf("Prompt() = %q, want the base prompt unchanged", got)
	}
}

func TestPromptAddsOnlyFilledFields(t *testing.T) {
	// Arrange
	p := Profile{AccountID: 1, BusinessName: "Johnstocker AI Studio", About: "Online courses", Contact: "LINE @johnstocker"}

	// Act
	got := Prompt("BASE", p)

	// Assert
	for _, want := range []string{"BASE", "Johnstocker AI Studio", "Online courses", "LINE @johnstocker"} {
		if !strings.Contains(got, want) {
			t.Errorf("prompt is missing %q:\n%s", want, got)
		}
	}
	for _, unwanted := range []string{"Tone", "Rules"} {
		if strings.Contains(got, unwanted) {
			t.Errorf("prompt has a heading for empty field %q:\n%s", unwanted, got)
		}
	}
	if !strings.HasPrefix(got, "BASE") {
		t.Errorf("base prompt must come first:\n%s", got)
	}
}

func TestValidateRejectsBadInput(t *testing.T) {
	cases := map[string]Profile{
		"no account":    {BusinessName: "x"},
		"long name":     {AccountID: 1, BusinessName: strings.Repeat("ก", MaxNameRunes+1)},
		"long rules":    {AccountID: 1, Rules: strings.Repeat("a", MaxFieldRunes+1)},
		"invalid utf-8": {AccountID: 1, About: "\xff"},
	}
	for name, p := range cases {
		t.Run(name, func(t *testing.T) {
			// Act
			err := p.Validate()

			// Assert
			if err == nil {
				t.Fatal("Validate() = nil, want an error")
			}
		})
	}
}

func TestValidateAcceptsThaiAtLimit(t *testing.T) {
	// Arrange: limits count characters, not bytes (Thai is 3 bytes each).
	p := Profile{AccountID: 1, BusinessName: strings.Repeat("ก", MaxNameRunes), About: strings.Repeat("ข", MaxFieldRunes)}

	// Act
	err := p.Validate()

	// Assert
	if err != nil {
		t.Fatalf("Validate() = %v, want nil", err)
	}
}

func TestNormalizeTrimsAndUnifiesNewlines(t *testing.T) {
	// Arrange
	p := Profile{AccountID: 1, BusinessName: "  Shop \n", Rules: "a\r\nb\r\n"}

	// Act
	got := p.Normalize()

	// Assert
	if got.BusinessName != "Shop" || got.Rules != "a\nb" {
		t.Fatalf("Normalize() = %+v", got)
	}
}
