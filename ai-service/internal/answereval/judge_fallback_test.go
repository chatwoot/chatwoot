package answereval

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"testing"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/llm"
)

type scriptedCompleter struct {
	reply string
	err   error
	calls int
}

func (s *scriptedCompleter) Complete(context.Context, []llm.Message) (llm.Result, error) {
	s.calls++
	if s.err != nil {
		return llm.Result{}, s.err
	}
	return llm.Result{Content: s.reply}, nil
}

const passJSON = `{"pass": true, "reason": "ok", "faithful": true, "context_recall": true}`

func rateLimited() error {
	return fmt.Errorf("wrapped: %w", &llm.StatusError{Code: 429, Message: "You have no credits remaining."})
}

func TestLLMJudge_UsesBackupOnlyWhenPrimaryIsRateLimited(t *testing.T) {
	cases := []struct {
		name        string
		primaryErr  error
		withBackup  bool
		wantErr     bool
		wantBackup  int
		wantCounted int64
	}{
		{"primary works", nil, true, false, 0, 0},
		{"429 goes to backup", rateLimited(), true, false, 1, 1},
		{"429 without backup fails", rateLimited(), false, true, 0, 0},
		{"500 does not switch", &llm.StatusError{Code: 500, Message: "boom"}, true, true, 0, 0},
		{"network error does not switch", errors.New("llm request: timeout"), true, true, 0, 0},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			// Arrange
			primary := &scriptedCompleter{reply: passJSON, err: c.primaryErr}
			backup := &scriptedCompleter{reply: passJSON}
			j := LLMJudge{LLM: primary, BackupUsed: new(BackupCounter)}
			if c.withBackup {
				j.Backup = backup
			}

			// Act
			v, err := j.Judge(context.Background(), JudgeInput{Case: Case{Turns: []string{"hi"}}})

			// Assert
			if (err != nil) != c.wantErr {
				t.Fatalf("err = %v, wantErr %v", err, c.wantErr)
			}
			if !c.wantErr && !v.Pass {
				t.Errorf("verdict = %+v", v)
			}
			if backup.calls != c.wantBackup || j.BackupUsed.Load() != c.wantCounted {
				t.Errorf("backup calls = %d counted = %d, want %d/%d", backup.calls, j.BackupUsed.Load(), c.wantBackup, c.wantCounted)
			}
		})
	}
}

func TestLLMJudge_BackupFailureKeepsBothErrors(t *testing.T) {
	// Arrange
	j := LLMJudge{LLM: &scriptedCompleter{err: rateLimited()}, Backup: &scriptedCompleter{err: errors.New("backup down")}}

	// Act
	_, err := j.Judge(context.Background(), JudgeInput{Case: Case{Turns: []string{"hi"}}})

	// Assert
	if err == nil || !llm.IsRateLimited(err) || !strings.Contains(err.Error(), "backup down") {
		t.Fatalf("err = %v", err)
	}
}
