package answereval

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"strings"
	"testing"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/llm"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/memory"
)

// byTurn answers "ok", fails with a provider 429 on "limited", and with a
// plain error on "broken".
type byTurn struct{}

func (byTurn) Answer(_ context.Context, _, _ int64, h []memory.Turn) (llm.Result, []knowledge.Hit, error) {
	switch h[len(h)-1].Content {
	case "limited":
		return llm.Result{}, nil, fmt.Errorf("primary: %w; fallback: %w",
			&llm.StatusError{Code: 429, Message: "no credits"}, &llm.StatusError{Code: 429, Message: "Rate limit exceeded"})
	case "broken":
		return llm.Result{}, nil, errors.New("reply: template error")
	}
	return llm.Result{Content: "ok"}, nil, nil
}

func skipCases() []Case {
	return []Case{
		{Name: "a", AccountID: 1, Turns: []string{"ok"}, Expect: ExpectAnswer},
		{Name: "b", AccountID: 1, Turns: []string{"limited"}, Expect: ExpectAnswer},
		{Name: "c", AccountID: 1, Turns: []string{"broken"}, Expect: ExpectAnswer},
	}
}

func TestRun_SkipsRateLimitedCasesOnlyWhenAsked(t *testing.T) {
	// Arrange
	judge := &fixedJudge{verdict: Verdict{Pass: true}}
	on := Runner{Answerer: byTurn{}, Handoff: keyword("คน"), Judge: judge, SkipRateLimited: true}
	off := on
	off.SkipRateLimited = false

	// Act
	skipped := Run(context.Background(), on, skipCases())
	strict := Run(context.Background(), off, skipCases())

	// Assert
	if skipped.Skipped != 1 || !skipped.Results[1].Skipped || skipped.Results[2].Skipped || skipped.Passed != 1 {
		t.Fatalf("skip on: skipped=%d results=%+v", skipped.Skipped, skipped.Results)
	}
	if skipped.Completed() != 2 || skipped.PassRate() != 0.5 {
		t.Errorf("completed=%d rate=%v, want 2 and 0.5 (a plain error still fails)", skipped.Completed(), skipped.PassRate())
	}
	if strict.Skipped != 0 || strict.Completed() != 3 || strict.PassRate() != 1.0/3 {
		t.Errorf("skip off: skipped=%d completed=%d rate=%v", strict.Skipped, strict.Completed(), strict.PassRate())
	}
}

func TestRun_SkipsWhenTheJudgeIsRateLimited(t *testing.T) {
	// Arrange
	r := Runner{Answerer: byTurn{}, Handoff: keyword("คน"), SkipRateLimited: true,
		Judge: LLMJudge{LLM: &scriptedCompleter{err: rateLimited()}}}

	// Act
	rep := Run(context.Background(), r, skipCases()[:1])

	// Assert
	if rep.Skipped != 1 || rep.Completed() != 0 || rep.PassRate() != 0 {
		t.Fatalf("skipped=%d completed=%d rate=%v", rep.Skipped, rep.Completed(), rep.PassRate())
	}
}

func TestReport_WriteShowsSkippedApart(t *testing.T) {
	// Arrange
	judge := &fixedJudge{verdict: Verdict{Pass: true}}
	rep := Run(context.Background(), Runner{Answerer: byTurn{}, Handoff: keyword("คน"), Judge: judge, SkipRateLimited: true}, skipCases())
	var out bytes.Buffer

	// Act
	rep.Write(&out)

	// Assert
	s := out.String()
	for _, want := range []string{"SKIP b [answer]", "FAIL c [answer]", "Passed 1/2", "skipped 1 (AI provider rate-limited)"} {
		if !strings.Contains(s, want) {
			t.Errorf("report misses %q:\n%s", want, s)
		}
	}
}
