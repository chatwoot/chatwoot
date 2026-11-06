// Package handoff detects when a customer asks to talk to a human.
package handoff

import "strings"

// Detector matches customer text against handoff keywords.
type Detector struct {
	keywords []string
}

// New returns a Detector. Keywords are matched case-insensitively as substrings,
// which suits Thai and Lao (no spaces between words).
func New(keywords []string) *Detector {
	d := &Detector{}
	for _, k := range keywords {
		if k = strings.ToLower(strings.TrimSpace(k)); k != "" {
			d.keywords = append(d.keywords, k)
		}
	}
	return d
}

// Wants reports whether text asks for a human.
func (d *Detector) Wants(text string) bool {
	lower := strings.ToLower(text)
	for _, k := range d.keywords {
		if strings.Contains(lower, k) {
			return true
		}
	}
	return false
}
