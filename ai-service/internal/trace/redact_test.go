package trace

import (
	"strings"
	"testing"
)

func TestRedactMasksPersonalData(t *testing.T) {
	cases := map[string]struct{ in, want string }{
		"email":              {"ส่งมาที่ somchai.k@gmail.com นะคะ", "ส่งมาที่ [EMAIL] นะคะ"},
		"thai mobile":        {"เบอร์ 0812345678 ค่ะ", "เบอร์ [PHONE] ค่ะ"},
		"mobile with dashes": {"โทร 081-234-5678", "โทร [PHONE]"},
		"mobile +66":         {"call +66 81 234 5678", "call [PHONE]"},
		"landline":           {"02-123-4567", "[PHONE]"},
		"thai national id":   {"บัตร 1-2345-67890-12-3", "บัตร [ID]"},
		"id no dashes":       {"เลขบัตร 1234567890123", "เลขบัตร [ID]"},
		"card number":        {"บัตร 4111 1111 1111 1111 ค่ะ", "บัตร [CARD] ค่ะ"},
		"bank account":       {"โอนเข้า 123-4-56789-0 กสิกร", "โอนเข้า [ACCOUNT] กสิกร"},
		"line id":            {"แอดไลน์ผม line id: somchai_99 ครับ", "แอดไลน์ผม line id: [LINE] ครับ"},
		"thai line id":       {"ไอดีไลน์ somchai99", "ไอดีไลน์ [LINE]"},
	}
	for name, c := range cases {
		t.Run(name, func(t *testing.T) {
			// Act
			got := Redact(c.in)

			// Assert
			if got != c.want {
				t.Errorf("Redact(%q) = %q, want %q", c.in, got, c.want)
			}
		})
	}
}

func TestRedactKeepsBusinessFacts(t *testing.T) {
	// Arrange: prices, dates, percentages and the shop's own LINE OA are not personal.
	in := "ราคา 3,900 บาท ผ่อน 3 เดือน 1,300 บาท ถึง 30 พฤศจิกายน 2569 ดูได้ 20% ทัก LINE Official @johnstockerai"

	// Act
	got := Redact(in)

	// Assert
	if got != in {
		t.Errorf("Redact changed business text:\n got %q\nwant %q", got, in)
	}
}

func TestPseudonymIsStableAndKeyed(t *testing.T) {
	// Arrange
	k1, k2 := []byte("key-one"), []byte("key-two")

	// Act
	a, b := Pseudonym(k1, "contact", 42), Pseudonym(k1, "contact", 42)
	otherKind, otherKey := Pseudonym(k1, "conversation", 42), Pseudonym(k2, "contact", 42)

	// Assert
	if a != b || len(a) != 16 {
		t.Fatalf("Pseudonym not stable or wrong length: %q %q", a, b)
	}
	if a == otherKind || a == otherKey {
		t.Error("kind and key must change the pseudonym")
	}
	if strings.Contains(a, "42") && len(a) < 4 {
		t.Error("pseudonym must not reveal the id")
	}
}
