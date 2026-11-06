package llm

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type stub struct {
	res   Result
	err   error
	calls int
}

func (s *stub) Complete(context.Context, []Message) (Result, error) {
	s.calls++
	return s.res, s.err
}

func TestFallback_PrimarySucceeds(t *testing.T) {
	// Arrange
	p, s := &stub{res: Result{Content: "p"}}, &stub{res: Result{Content: "s"}}
	f := &Fallback{Primary: p, Secondary: s}

	// Act
	res, err := f.Complete(context.Background(), nil)

	// Assert
	if err != nil || res.Content != "p" || res.UsedFallback || s.calls != 0 {
		t.Errorf("res=%+v err=%v secondaryCalls=%d", res, err, s.calls)
	}
}

func TestFallback_UsesSecondaryOnPrimaryError(t *testing.T) {
	// Arrange
	p, s := &stub{err: errors.New("503")}, &stub{res: Result{Content: "s"}}
	f := &Fallback{Primary: p, Secondary: s}

	// Act
	res, err := f.Complete(context.Background(), nil)

	// Assert
	if err != nil || res.Content != "s" || !res.UsedFallback || p.calls != 1 || s.calls != 1 {
		t.Errorf("res=%+v err=%v calls=%d/%d", res, err, p.calls, s.calls)
	}
}

func TestFallback_BothFailReportsBoth(t *testing.T) {
	// Arrange
	p, s := &stub{err: errors.New("primary down")}, &stub{err: errors.New("fallback down")}
	f := &Fallback{Primary: p, Secondary: s}

	// Act
	_, err := f.Complete(context.Background(), nil)

	// Assert
	if err == nil || !strings.Contains(err.Error(), "primary down") || !strings.Contains(err.Error(), "fallback down") {
		t.Errorf("err = %v", err)
	}
}

func TestFallback_NoSecondaryReturnsPrimaryError(t *testing.T) {
	// Arrange
	want := errors.New("boom")
	f := &Fallback{Primary: &stub{err: want}}

	// Act
	_, err := f.Complete(context.Background(), nil)

	// Assert
	if !errors.Is(err, want) {
		t.Errorf("err = %v", err)
	}
}

func TestFallback_SkipsSecondaryWhenContextDone(t *testing.T) {
	// Arrange
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	s := &stub{res: Result{Content: "s"}}
	f := &Fallback{Primary: &stub{err: context.Canceled}, Secondary: s}

	// Act
	_, err := f.Complete(ctx, nil)

	// Assert
	if err == nil || s.calls != 0 {
		t.Errorf("err=%v secondaryCalls=%d", err, s.calls)
	}
}

func TestFallback_NotConfigured(t *testing.T) {
	// Arrange
	f := &Fallback{}

	// Act
	_, err := f.Complete(context.Background(), nil)

	// Assert
	if !errors.Is(err, ErrNotConfigured) {
		t.Errorf("err = %v", err)
	}
}
