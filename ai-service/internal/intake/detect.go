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
	secretValue = []struct {
		re   *regexp.Regexp
		kind string
	}{
		{regexp.MustCompile(`(?i)\b(?:cvv|cvc|cvv2)\s*(?:[:=]|คือ|is)\s*\d{3,4}\b`), "security code"},
		{regexp.MustCompile(`(?i)(?:\botp\b|รหัส\s*otp|one[- ]time (?:code|password))\s*(?:[:=]|คือ|is)\s*\d{4,8}`), "one-time code"},
		{regexp.MustCompile(`(?i)(?:\bpassword\b|\bpasscode\b|รหัสผ่าน|\bpin\b)\s*(?:[:=]|คือ|is)\s*\S{3,}`), "password"},
	}
	// numberRun is one number written with separators between its digits:
	// up to two spaces, dots, dashes, slashes or underscores (not commas,
	// so a list of numbers stays apart).
	// looseRun joins digit groups across any one or two characters that
	// are not letters or line breaks; used only for the private checks.
	looseRun    = regexp.MustCompile(`\d(?:[^\p{L}\p{N}\n]{0,2}\d)*`)
	numberRun   = regexp.MustCompile(`\+?\d(?:[ \t.\-/_]{0,2}\d)*`)
	promptPayKW = regexp.MustCompile(`(?i)พร้อมเพย์|prompt\s*pay`)
	bankKW      = regexp.MustCompile(`(?i)บัญชี|ธนาคาร|\bbank\b|\baccount\b|\bacct\b|กสิกร|ไทยพาณิชย์|กรุงเทพ|กรุงไทย|กรุงศรี|\bkbank\b|\bscb\b|\bbbl\b|\bktb\b|\bttb\b|ออมสิน`)
	link        = regexp.MustCompile(`(?i)https?://[^\s<>"')]+`)
	payLink     = regexp.MustCompile(`(?i)pay|checkout|omise|stripe|2c2p|gbprime|promptpay|billing|invoice`)
	lineLink    = regexp.MustCompile(`(?i)^https?://(?:[a-z0-9-]+\.)?line\.me/`)
	email       = regexp.MustCompile(`(?i)\b[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}\b`)
	lineID      = regexp.MustCompile(`(?i)(?:\bline\b|ไลน์|line\s*id)[^@\n]{0,20}@[a-z0-9._-]{3,}`)
	handle      = regexp.MustCompile(`(?i)(?:^|[^a-z0-9._%+-])@[a-z0-9._-]{3,}`)
)

// drop removes a match without recording anything.
const drop = "-"

// contextRunes is how far before a number its keyword (PromptPay, bank) may be.
const contextRunes = 40

// Detect runs the pattern checks. Links, emails and secret values go first;
// then every number is read whole and judged once, private checks first, so
// no payment or contact pattern can swallow a card or ID number.
func Detect(text string) Signals {
	s := clean(text)
	var sig Signals
	take := func(re *regexp.Regexp, keep func(m string) string) {
		s = re.ReplaceAllStringFunc(s, func(m string) string {
			switch kind := keep(m); kind {
			case "":
				return m
			case drop:
				return " "
			default:
				add(&sig, kind)
				return " "
			}
		})
	}
	always := func(kind string) func(string) string { return func(string) string { return kind } }

	for _, sv := range secretValue {
		take(sv.re, always(sv.kind))
	}
	// Private numbers first, on the whole text: inside links and emails
	// too, and with any separator (commas included) between digit groups.
	for _, m := range looseRun.FindAllString(s, -1) {
		if d := digits(m); len(d) >= 13 && len(d) <= 19 && luhn(d) {
			add(&sig, "card number")
		} else if len(d) == 13 && validThaiID(d) && !promptPayKW.MatchString(s) {
			add(&sig, "ID number")
		}
	}
	take(link, func(m string) string {
		switch {
		case lineLink.MatchString(m):
			return "LINE"
		case payLink.MatchString(m):
			return "payment link"
		}
		return drop // a plain link: removed so its digits are not read as numbers
	})
	take(email, always("email"))
	for _, loc := range numberRun.FindAllStringIndex(s, -1) {
		if kind := numberKind(s[loc[0]:loc[1]], before(s, loc[0])); kind != "" {
			add(&sig, kind)
		}
	}
	s = numberRun.ReplaceAllString(s, " ")
	take(lineID, always("LINE"))
	take(handle, always("LINE"))
	return sig
}

// before is the text on the same line just before i.
func before(s string, i int) string {
	pre := s[:i]
	if nl := strings.LastIndexByte(pre, '\n'); nl >= 0 {
		pre = pre[nl+1:]
	}
	if r := []rune(pre); len(r) > contextRunes {
		pre = string(r[len(r)-contextRunes:])
	}
	return pre
}

// numberKind judges one whole number. Private checks come first.
func numberKind(raw, context string) string {
	d := digits(raw)
	switch {
	case hasCard(d):
		return "card number"
	case hasThaiID(d):
		if promptPayKW.MatchString(context) && len(d) == 13 {
			return "PromptPay"
		}
		return "ID number"
	case promptPayKW.MatchString(context) && phoneShaped(raw, d):
		return "PromptPay"
	case bankKW.MatchString(context) && len(d) >= 10 && len(d) <= 12:
		return "bank account"
	case phoneShaped(raw, d):
		return "phone"
	}
	return ""
}

// hasCard reports a Luhn-valid card number: the whole number (13–19
// digits), or a 15- or 16-digit card at the start or end of a longer one,
// so digits stuck before or after a card cannot hide it. Inner windows are
// not tried: one in ten random windows passes Luhn.
func hasCard(d string) bool {
	if len(d) >= 13 && len(d) <= 19 && luhn(d) {
		return true
	}
	if len(d) <= 16 {
		return false
	}
	for _, n := range []int{15, 16} {
		if n < len(d) && (luhn(d[:n]) || luhn(d[len(d)-n:])) {
			return true
		}
	}
	return false
}

// hasThaiID reports a checksum-valid 13-digit ID number anywhere in d.
func hasThaiID(d string) bool {
	for i := 0; i+13 <= len(d); i++ {
		if validThaiID(d[i : i+13]) {
			return true
		}
	}
	return false
}

// phoneShaped is a Thai phone number: 0 and 8–9 digits, or +66 and 8–9.
func phoneShaped(raw, d string) bool {
	if strings.HasPrefix(raw, "+") {
		return strings.HasPrefix(d, "66") && len(d) >= 10 && len(d) <= 11
	}
	return strings.HasPrefix(d, "0") && len(d) >= 9 && len(d) <= 10
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
