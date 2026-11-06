package webhook

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"strconv"
	"strings"
	"time"
)

// MaxClockSkew bounds how old a signed request may be (replay protection).
const MaxClockSkew = 5 * time.Minute

// Signature errors.
var (
	ErrMissingSignature = errors.New("missing signature headers")
	ErrStaleTimestamp   = errors.New("timestamp outside allowed window")
	ErrBadSignature     = errors.New("signature mismatch")
)

// Verify checks Chatwoot's webhook signature:
// X-Chatwoot-Signature = "sha256=" + hex(HMAC-SHA256(secret, timestamp + "." + body)).
// Source: chatwoot lib/webhooks/trigger.rb#request_headers.
func Verify(secret, timestamp, signature string, body []byte, now time.Time) error {
	if timestamp == "" || signature == "" {
		return ErrMissingSignature
	}
	ts, err := strconv.ParseInt(timestamp, 10, 64)
	if err != nil {
		return ErrStaleTimestamp
	}
	if d := now.Sub(time.Unix(ts, 0)); d > MaxClockSkew || d < -MaxClockSkew {
		return ErrStaleTimestamp
	}
	got, ok := strings.CutPrefix(signature, "sha256=")
	if !ok {
		return ErrBadSignature
	}
	gotBytes, err := hex.DecodeString(got)
	if err != nil {
		return ErrBadSignature
	}
	if !hmac.Equal(gotBytes, Sign(secret, timestamp, body)) {
		return ErrBadSignature
	}
	return nil
}

// Sign computes the raw HMAC for a timestamp and body.
func Sign(secret, timestamp string, body []byte) []byte {
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write([]byte(timestamp))
	mac.Write([]byte("."))
	mac.Write(body)
	return mac.Sum(nil)
}
