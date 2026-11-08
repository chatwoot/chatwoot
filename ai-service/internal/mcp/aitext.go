package mcp

import (
	"regexp"
	"strings"
	"unicode"

	"golang.org/x/text/unicode/norm"
)

// Text an AI app writes over MCP into what customers are told (the business
// profile and knowledge documents) must not carry payment or contact details:
// a prompt-injected app could otherwise send customers to someone else's bank
// account or LINE. intake.Detect is tuned for customer messages and avoids
// false alarms; this check is deliberately stricter, because the owner can
// always make the same edit on /admin. It is a filter, not a proof: wording
// alone ("pay via our Facebook page") still gets through, which is why owner
// approval of AI edits is the follow-up.
var (
	aiLink  = regexp.MustCompile(`(?i)[a-z][a-z0-9+.-]*://|\bwww\.|\b[a-z0-9-]+(?:\.[a-z0-9-]+)*\.[a-z]{2,}\b`)
	aiWords = regexp.MustCompile(`(?i)\bline\s*(?:id|oa|official)\b|\bline\s*[:@]|ไลน์|พร้อมเพย์|\bprompt\s*pay\b|โอน|บัญชี|\bbank\b|\baccount\b|\bacct\b|\btransfer\b|\biban\b|\bwallet\b|true\s*money` +
		`|ธนาคาร|กสิกร|ไทยพาณิชย์|กรุงไทย|กรุงศรี|ออมสิน|\b(?:kbank|kasikorn\w*|scb|ktb|bbl|ttb|gsb|krungsri|krungthai)\b`)
	aiLINE = regexp.MustCompile(`\bLINE\b`)
	// aiNumberLines is one number, with up to six non-letter characters
	// (spaces, dashes, commas, colons, line breaks...) between digit groups.
	aiNumberLines = regexp.MustCompile(`\d(?:[^\p{L}\p{N}]{0,6}\d)*`)
	aiBigPrice    = regexp.MustCompile(`^[1-9]\d{0,2}(?:,\d{3}){2}`)
	aiCurrency    = regexp.MustCompile(`(?i)฿|บาท|\bbaht\b|\bthb\b`)
	aiSpaces      = regexp.MustCompile(`[^\S\n]+`)
	aiBreaks      = regexp.MustCompile(`\s*\n\s*`)
	// aiSafeNumber is a time, a date or a price, or a range of two of the
	// same kind: long, but not an account or phone number.
	aiSafeNumber = func() *regexp.Regexp {
		year := `(?:19|20|25)\d{2}`
		month := `(?:0?[1-9]|1[0-2])`
		day := `(?:0?[1-9]|[12]\d|3[01])`
		kinds := []string{
			`(?:[01]?\d|2[0-4])[:.][0-5]\d`, // time
			`(?:` + year + `-` + month + `-` + day + `|` + day + `/` + month + `/(?:` + year + `|\d{2}))`, // date
			`[1-9]\d{0,2}(?:,\d{3}){1,2}(?:\.\d{1,2})?`,                                                   // price up to 999,999,999
		}
		var alts []string
		for _, k := range kinds {
			alts = append(alts, k+`(?:\s*[-–]\s*`+k+`)?`)
		}
		return regexp.MustCompile(`^(?:` + strings.Join(alts, `|`) + `)$`)
	}()
)

// aiMaxDigits is the most digits a number may have before it could be a
// phone, account or card number (Thai phones have 9-10, accounts 10+).
const aiMaxDigits = 6

// checkAIText refuses field text an AI app may not write. The error does not
// say which rule matched, so an injected app cannot probe for a gap.
func checkAIText(field, text string) error {
	s := aiDigits(text)
	if aiLink.MatchString(s) || strings.ContainsAny(s, "@＠") || aiWords.MatchString(s) || aiLINE.MatchString(s) || aiLongNumber(s) {
		return userError(field + ": an AI tool cannot add links, @handles, long numbers or payment and contact words " +
			"(LINE, PromptPay, bank account, transfer); the owner adds these on the admin page")
	}
	return nil
}

// aiLongNumber reports a number with more than aiMaxDigits digits that is
// not a time, date or price on one line. A number that runs over a line break
// is never treated as safe, so "08:12" on one line and "345678" on the next is
// one ten-digit number. A price over six digits needs a currency on its line.
func aiLongNumber(s string) bool {
	for _, loc := range aiNumberLines.FindAllStringIndex(s, -1) {
		m := s[loc[0]:loc[1]]
		if digitCount(m) <= aiMaxDigits {
			continue
		}
		if !strings.Contains(m, "\n") && aiSafeNumber.MatchString(m) &&
			(!aiBigPrice.MatchString(m) || aiCurrency.MatchString(lineAt(s, loc[0]))) {
			continue
		}
		return true
	}
	return false
}

// lineAt is the line of s that holds byte i.
func lineAt(s string, i int) string {
	start := strings.LastIndexByte(s[:i], '\n') + 1
	end := strings.IndexByte(s[i:], '\n')
	if end < 0 {
		return s[start:]
	}
	return s[start : i+end]
}

func digitCount(s string) int {
	n := 0
	for _, r := range s {
		if r >= '0' && r <= '9' {
			n++
		}
	}
	return n
}

// aiDigits writes every digit form (Thai, full-width, circled...) as ASCII, and
// reads O, o, I and l next to a digit as 0 or 1 ("O81-234-5678").
func aiDigits(text string) string {
	// NFKC turns full-width and other look-alike forms (＠ ﹫ ｗ ． ① ¹) into
	// plain ones; a few dots it leaves are mapped by hand.
	text = strings.NewReplacer("。", ".", "｡", ".", "︒", ".").Replace(norm.NFKC.String(text))
	text = aiBreaks.ReplaceAllString(aiSpaces.ReplaceAllString(visible(text), " "), "\n")
	rs := []rune(text)
	out := make([]rune, len(rs))
	for i, r := range rs {
		out[i] = asciiDigit(r)
	}
	isDigit := func(i int) bool { return i >= 0 && i < len(out) && out[i] >= '0' && out[i] <= '9' }
	for i, r := range out {
		if !isDigit(i-1) && !isDigit(i+1) {
			continue
		}
		switch r {
		case 'O', 'o':
			out[i] = '0'
		case 'I', 'l':
			out[i] = '1'
		}
	}
	return string(out)
}

// visible drops invisible characters (zero-width spaces and joiners, soft
// hyphens, direction marks) and combining marks that do not sit on a Thai
// letter, so "Prompt\u200bPay" reads as PromptPay. Thai vowel and tone marks
// stay.
func visible(text string) string {
	var b strings.Builder
	prev := rune(0)
	for _, r := range text {
		switch {
		case unicode.In(r, unicode.Cf, unicode.Variation_Selector, unicode.Other_Default_Ignorable_Code_Point):
			continue
		case unicode.In(r, unicode.Mn, unicode.Me) && !unicode.Is(unicode.Thai, prev):
			continue
		}
		b.WriteRune(r)
		prev = r
	}
	return b.String()
}

func asciiDigit(r rune) rune {
	switch {
	case r >= '0' && r <= '9':
		return r
	case r >= '๐' && r <= '๙':
		return '0' + (r - '๐')
	case r >= '０' && r <= '９':
		return '0' + (r - '０')
	case unicode.IsNumber(r):
		return '9' // another digit form: still counted as a digit
	}
	return r
}
