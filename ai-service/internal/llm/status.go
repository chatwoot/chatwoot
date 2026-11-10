package llm

import (
	"errors"
	"fmt"
	"net/http"
)

// StatusError is a provider's error response: the HTTP status and its
// message. Its text keeps the earlier "llm status N: message" form.
type StatusError struct {
	Code    int
	Message string
}

func (e *StatusError) Error() string { return fmt.Sprintf("llm status %d: %s", e.Code, e.Message) }

// IsRateLimited reports whether err (possibly wrapped) is a provider's 429:
// too many requests, or for OpenAI also "no credits remaining".
func IsRateLimited(err error) bool {
	var se *StatusError
	return errors.As(err, &se) && se.Code == http.StatusTooManyRequests
}
