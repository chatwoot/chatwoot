// Package trace sends one trace per customer message to Langfuse over
// OTLP/HTTP JSON, using only the standard library. Customer text is redacted
// (or left out entirely) and Chatwoot ids are replaced by keyed pseudonyms
// before anything leaves the server.
package trace

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"regexp"
	"strconv"
)

// Order matters: specific number shapes (ID, card) before phones and accounts.
var redactions = []struct {
	re   *regexp.Regexp
	repl string
}{
	{regexp.MustCompile(`[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}`), "[EMAIL]"},
	// Thai national ID: 13 digits, often written 1-2345-67890-12-3.
	{regexp.MustCompile(`\b\d-?\d{4}-?\d{5}-?\d{2}-?\d\b`), "[ID]"},
	// Payment cards: 13–19 digits, optionally grouped by spaces or dashes.
	{regexp.MustCompile(`\b(?:\d[ -]?){12,18}\d\b`), "[CARD]"},
	// Thai phones: 0 or +66, then 8 (landline) or 9 (mobile) digits in any grouping.
	{regexp.MustCompile(`(?:\+66[ .-]?|\b0)\d(?:[ .-]?\d){7,8}\b`), "[PHONE]"},
	// Thai bank accounts: 10 digits, often written 123-4-56789-0.
	{regexp.MustCompile(`\b\d{3}-?\d-?\d{5}-?\d\b`), "[ACCOUNT]"},
	// Catch-all: any other run of 9+ digits (parcel, order, account numbers in
	// unusual groupings). Prices use commas and stay readable.
	{regexp.MustCompile(`\b\d(?:[ .-]?\d){8,}\b`), "[NUMBER]"},
	// A personal LINE ID after an explicit label (not the shop's "LINE Official @...").
	{regexp.MustCompile(`(?i)((?:line\s*id|id\s*line|ไอดีไลน์|ไลน์ไอดี)\s*[:：]?\s*)@?[A-Za-z0-9._-]{3,}`), "${1}[LINE]"},
}

// Redact masks personal data in free text: emails, phone numbers, Thai
// national IDs, card and bank account numbers, other long digit runs, and
// labelled LINE IDs. Prices, dates and the shop's own contact details stay
// readable. It is best effort: names and street addresses are not detected.
// Use TRACE_TEXT=off when no chat text may leave the server.
func Redact(s string) string {
	for _, r := range redactions {
		s = r.re.ReplaceAllString(s, r.repl)
	}
	return s
}

// Pseudonym replaces a Chatwoot id with a keyed hash, so one customer's turns
// can be grouped in Langfuse without revealing who they are.
func Pseudonym(key []byte, kind string, id int64) string {
	m := hmac.New(sha256.New, key)
	m.Write([]byte(kind + ":" + strconv.FormatInt(id, 10)))
	return hex.EncodeToString(m.Sum(nil))[:16]
}

func base64Std(s string) string { return base64.StdEncoding.EncodeToString([]byte(s)) }

// PseudonymKey derives the HMAC key for pseudonyms from a secret that stays
// on our server (the Chatwoot webhook secret). It must never be the Langfuse
// secret key: Langfuse knows that key and could recompute the hashes of small
// numeric ids, which would undo the pseudonyms.
func PseudonymKey(localSecret string) []byte {
	m := hmac.New(sha256.New, []byte(localSecret))
	m.Write([]byte("ai-service trace-pseudonym v1"))
	return m.Sum(nil)
}
