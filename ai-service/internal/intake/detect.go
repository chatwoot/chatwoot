package intake

import (
	"regexp"
	"slices"
	"strings"
	"unicode"
)

// Signals are what the pattern checks found. Private wins over the rest.
type Signals struct {
	Private []string // card number, security code, one-time code, password, ID number
	Payment []string // bank account, PromptPay, payment link
	Contact []string // phone, LINE, email
}

var (
	// sep is what may sit between digits of one number: up to two
	// characters that are not letters, digits or line breaks.
	thaiID      = regexp.MustCompile(`\b\d(?:` + sep + `\d){12}\b`)
	cardNumber  = regexp.MustCompile(`\b\d(?:` + sep + `\d){12,18}\b`)
	secretValue = []struct {
		re   *regexp.Regexp
		kind string
	}{
		{regexp.MustCompile(`(?i)\b(?:cvv|cvc|cvv2)\s*(?:[:=]|คือ|is)\s*\d{3,4}\b`), "security code"},
		{regexp.MustCompile(`(?i)(?:\botp\b|รหัส\s*otp|one[- ]time (?:code|password))\s*(?:[:=]|คือ|is)\s*\d{4,8}`), "one-time code"},
		{regexp.MustCompile(`(?i)(?:\bpassword\b|\bpasscode\b|รหัสผ่าน|\bpin\b)\s*(?:[:=]|คือ|is)\s*\S{3,}`), "password"},
	}
	promptPay   = regexp.MustCompile(`(?i)(?:พร้อมเพย์|prompt\s*pay)[^\d\n]{0,20}((?:\+` + sep + `6` + sep + `6|0)(?:` + sep + `\d){8,9}|\d(?:` + sep + `\d){12})`)
	bankAccount = regexp.MustCompile(`(?i)(?:บัญชี|ธนาคาร|\bbank\b|\baccount\b|\bacct\b|กสิกร|ไทยพาณิชย์|กรุงเทพ|กรุงไทย|กรุงศรี|\bkbank\b|\bscb\b|\bbbl\b|\bktb\b|\bttb\b|ออมสิน)[^\d\n]{0,30}(\d(?:` + sep + `\d){9,11})\b`)
	link        = regexp.MustCompile(`(?i)https?://[^\s<>"')]+`)
	payLink     = regexp.MustCompile(`(?i)pay|checkout|omise|stripe|2c2p|gbprime|promptpay|billing|invoice`)
	lineLink    = regexp.MustCompile(`(?i)^https?://(?:[a-z0-9-]+\.)?line\.me/`)
	email       = regexp.MustCompile(`(?i)\b[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}\b`)
	lineID      = regexp.MustCompile(`(?i)(?:\bline\b|ไลน์|line\s*id)[^@\n]{0,20}@[a-z0-9._-]{3,}`)
	phone       = regexp.MustCompile(`(?:\+` + sep + `6` + sep + `6|\b0)(?:` + sep + `\d){8,9}\b`)
	handle      = regexp.MustCompile(`(?i)(?:^|[^a-z0-9._%+-])@[a-z0-9._-]{3,}`)
)

const sep = `[^\p{L}\p{N}\n]{0,2}`

// Detect runs the pattern checks. Each match is removed before the next
// check, so one number is counted once (a PromptPay phone is payment, not
// also a contact phone).
func Detect(text string) Signals {
	s := clean(text)
	var sig Signals
	take := func(re *regexp.Regexp, keep func(m string) string) {
		s = re.ReplaceAllStringFunc(s, func(m string) string {
			if kind := keep(m); kind != "" {
				add(&sig, kind)
				return " "
			}
			return m
		})
	}
	always := func(kind string) func(string) string { return func(string) string { return kind } }

	take(promptPay, always("PromptPay"))
	take(bankAccount, always("bank account"))
	for _, sv := range secretValue {
		take(sv.re, always(sv.kind))
	}
	take(thaiID, func(m string) string {
		if validThaiID(digits(m)) {
			return "ID number"
		}
		return ""
	})
	take(cardNumber, func(m string) string {
		if d := digits(m); len(d) >= 13 && luhn(d) {
			return "card number"
		}
		return ""
	})
	take(link, func(m string) string {
		switch {
		case lineLink.MatchString(m):
			return "LINE"
		case payLink.MatchString(m):
			return "payment link"
		}
		return ""
	})
	take(email, always("email"))
	take(lineID, always("LINE"))
	take(phone, always("phone"))
	take(handle, always("LINE"))
	return sig
}

func add(sig *Signals, kind string) {
	var dst *[]string
	switch kind {
	case "card number", "security code", "one-time code", "password", "ID number":
		dst = &sig.Private
	case "bank account", "PromptPay", "payment link":
		dst = &sig.Payment
	default:
		dst = &sig.Contact
	}
	if !slices.Contains(*dst, kind) {
		*dst = append(*dst, kind)
	}
}

// clean drops zero-width and format characters, turns every kind of space
// into a plain space and full-width or Thai digits into ASCII, so hidden
// separators cannot break a number apart.
func clean(s string) string {
	return strings.Map(func(r rune) rune {
		switch {
		case unicode.Is(unicode.Cf, r):
			return -1
		case unicode.IsSpace(r) && r != '\n':
			return ' '
		case unicode.Is(unicode.Pd, r) || r == '−':
			return '-'
		case unicode.IsDigit(r) && r > '9':
			if d := digitValue(r); d >= 0 {
				return '0' + rune(d)
			}
		}
		return r
	}, s)
}

func digits(s string) string {
	return strings.Map(func(r rune) rune {
		if r >= '0' && r <= '9' {
			return r
		}
		return -1
	}, s)
}

func luhn(d string) bool {
	sum, double := 0, false
	for i := len(d) - 1; i >= 0; i-- {
		n := int(d[i] - '0')
		if double {
			if n *= 2; n > 9 {
				n -= 9
			}
		}
		sum += n
		double = !double
	}
	return sum%10 == 0
}

// validThaiID checks the 13-digit Thai ID checksum (also used for company
// tax IDs).
func validThaiID(d string) bool {
	if len(d) != 13 {
		return false
	}
	sum := 0
	for i := range 12 {
		sum += int(d[i]-'0') * (13 - i)
	}
	return (11-sum%11)%10 == int(d[12]-'0')
}

// digitValue is the value of a decimal digit in any script (Thai, full-width,
// Arabic-Indic, ...), or -1.
func digitValue(r rune) int {
	for _, t := range unicode.Nd.R16 {
		if uint16(r) >= t.Lo && uint16(r) <= t.Hi && r <= 0xFFFF {
			return int((uint16(r) - t.Lo) % 10)
		}
	}
	for _, t := range unicode.Nd.R32 {
		if uint32(r) >= t.Lo && uint32(r) <= t.Hi {
			return int((uint32(r) - t.Lo) % 10)
		}
	}
	return -1
}
