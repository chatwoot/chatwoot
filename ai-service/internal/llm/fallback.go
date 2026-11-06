package llm

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
)

// Completer is anything that can produce a chat completion.
type Completer interface {
	Complete(ctx context.Context, messages []Message) (Result, error)
}

// ErrNotConfigured means no provider has been set up yet.
var ErrNotConfigured = errors.New("llm provider not configured")

// Fallback tries Primary and, if it fails, Secondary once.
// A nil Secondary means no fallback.
type Fallback struct {
	Primary   Completer
	Secondary Completer
	Logger    *slog.Logger
}

// Complete implements Completer.
func (f *Fallback) Complete(ctx context.Context, messages []Message) (Result, error) {
	if f.Primary == nil {
		return Result{}, ErrNotConfigured
	}
	res, err := f.Primary.Complete(ctx, messages)
	if err == nil {
		return res, nil
	}
	// The caller gave up (shutdown or overall budget spent): don't start another call.
	if f.Secondary == nil || ctx.Err() != nil {
		return Result{}, err
	}
	if f.Logger != nil {
		f.Logger.Warn("primary llm failed, trying fallback", "error", err)
	}
	res, fbErr := f.Secondary.Complete(ctx, messages)
	if fbErr != nil {
		return Result{}, fmt.Errorf("primary: %w; fallback: %w", err, fbErr)
	}
	res.UsedFallback = true
	return res, nil
}
