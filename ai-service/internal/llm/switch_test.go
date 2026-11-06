package llm

import (
	"context"
	"errors"
	"testing"
)

func TestSwitch_EmptyIsNotConfigured(t *testing.T) {
	// Arrange
	var s Switch

	// Act
	_, err := s.Complete(context.Background(), nil)

	// Assert
	if !errors.Is(err, ErrNotConfigured) {
		t.Errorf("err = %v", err)
	}
}

func TestSwitch_DelegatesToLatestTarget(t *testing.T) {
	// Arrange
	var s Switch
	s.Set(&stub{res: Result{Content: "old"}})
	s.Set(&stub{res: Result{Content: "new"}})

	// Act
	res, err := s.Complete(context.Background(), nil)

	// Assert
	if err != nil || res.Content != "new" {
		t.Errorf("res=%+v err=%v", res, err)
	}
}
