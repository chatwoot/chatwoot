package knowledge

import (
	"context"
	"fmt"
	"io"
	"strings"
)

// EvalCase is one test question. Expect is part of the title of the document
// that should be found; an empty Expect means the knowledge base has no
// answer and retrieval should return nothing (the bot should hand off).
type EvalCase struct {
	Question  string `json:"question"`
	AccountID int64  `json:"account_id"`
	InboxID   int64  `json:"inbox_id"`
	Expect    string `json:"expect"`
}

// EvalResult is the outcome of one case.
type EvalResult struct {
	Case     EvalCase
	Pass     bool
	Rank     int // 1-based rank of the expected document; 0 = not found
	TopTitle string
	TopScore float64
	Err      error
}

// EvalReport summarises a run.
type EvalReport struct {
	Results []EvalResult
	// Answerable cases: share found in the top K, and mean reciprocal rank.
	Answerable, Found int
	MRR               float64
	// Unanswerable cases: share where nothing passed the score threshold.
	Unanswerable, Empty int
}

// Retrieve is the search under test (normally Service.Retrieve).
type Retrieve func(ctx context.Context, accountID, inboxID int64, queries ...string) ([]Hit, error)

// Evaluate runs every case through retrieve.
func Evaluate(ctx context.Context, retrieve Retrieve, cases []EvalCase) EvalReport {
	var rep EvalReport
	var rrSum float64
	for _, c := range cases {
		acct := c.AccountID
		if acct == 0 {
			acct = 1
		}
		hits, err := retrieve(ctx, acct, c.InboxID, c.Question)
		r := EvalResult{Case: c, Err: err}
		if len(hits) > 0 {
			r.TopTitle, r.TopScore = hits[0].Title, hits[0].Score
		}
		want := strings.ToLower(strings.TrimSpace(c.Expect))
		if want == "" {
			rep.Unanswerable++
			r.Pass = err == nil && len(hits) == 0
			if r.Pass {
				rep.Empty++
			}
		} else {
			rep.Answerable++
			for i, h := range hits {
				if strings.Contains(strings.ToLower(h.Title), want) {
					r.Rank = i + 1
					break
				}
			}
			r.Pass = err == nil && r.Rank > 0
			if r.Pass {
				rep.Found++
				rrSum += 1 / float64(r.Rank)
			}
		}
		rep.Results = append(rep.Results, r)
	}
	if rep.Answerable > 0 {
		rep.MRR = rrSum / float64(rep.Answerable)
	}
	return rep
}

// Write prints the report as plain text.
func (rep EvalReport) Write(w io.Writer) {
	for i, r := range rep.Results {
		status := "PASS"
		if !r.Pass {
			status = "FAIL"
		}
		expect := r.Case.Expect
		if expect == "" {
			expect = "(no answer → hand off)"
		}
		fmt.Fprintf(w, "%-4s #%d %q\n     expect: %s | rank: %d | top: %q (%.3f)", status, i+1, r.Case.Question, expect, r.Rank, r.TopTitle, r.TopScore)
		if r.Err != nil {
			fmt.Fprintf(w, " | error: %v", r.Err)
		}
		fmt.Fprintln(w)
	}
	fmt.Fprintf(w, "\nAnswerable:   %d/%d found (%.0f%%), MRR %.3f\n", rep.Found, rep.Answerable, pct(rep.Found, rep.Answerable), rep.MRR)
	fmt.Fprintf(w, "Unanswerable: %d/%d returned nothing (%.0f%%)\n", rep.Empty, rep.Unanswerable, pct(rep.Empty, rep.Unanswerable))
}

func pct(a, b int) float64 {
	if b == 0 {
		return 100
	}
	return 100 * float64(a) / float64(b)
}
