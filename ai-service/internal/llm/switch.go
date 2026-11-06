package llm

import (
	"context"
	"sync/atomic"
)

// Switch is a Completer whose target can be replaced at runtime (e.g. after
// an admin saves new provider settings). In-flight calls finish on the old target.
type Switch struct {
	current atomic.Pointer[completerBox]
}

type completerBox struct{ c Completer }

// Set replaces the target Completer.
func (s *Switch) Set(c Completer) { s.current.Store(&completerBox{c}) }

// Complete implements Completer.
func (s *Switch) Complete(ctx context.Context, messages []Message) (Result, error) {
	box := s.current.Load()
	if box == nil || box.c == nil {
		return Result{}, ErrNotConfigured
	}
	return box.c.Complete(ctx, messages)
}
