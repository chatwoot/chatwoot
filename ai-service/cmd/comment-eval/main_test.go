package main

import (
	"errors"
	"math"
	"testing"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/comments"
)

func TestLoadCases_TheMockSetIsValid(t *testing.T) {
	// Act
	cases, err := loadCases("../../testdata/comment-eval/cases.jsonl")

	// Assert
	if err != nil || len(cases) < 40 {
		t.Fatalf("cases %d err %v", len(cases), err)
	}
	pass := 0
	for _, c := range cases {
		if c.WantPass {
			pass++
			if c.WantIntent != comments.IntentLead && c.WantIntent != comments.IntentQuestion {
				t.Errorf("%s: only leads and questions can pass", c.ID)
			}
			if len(comments.Flags(c.Draft)) > 0 {
				t.Errorf("%s: a passing draft trips the code rules: %v", c.ID, comments.Flags(c.Draft))
			}
		}
	}
	if pass == 0 || pass == len(cases) {
		t.Fatalf("labels are one-sided: %d of %d pass", pass, len(cases))
	}
}

func TestSummarize(t *testing.T) {
	// Arrange
	lead := map[comments.Intent]float64{comments.IntentLead: 1}
	sure := map[string]float64{comments.CheckAnswersComment: 1, comments.CheckNoUnbackedOffer: 1, comments.CheckToneFits: 1, comments.CheckGenuine: 1}
	ok := comments.Review{Intent: comments.IntentLead, PIntent: lead, Checks: sure, Pass: true, InputTokens: 1000, OutputTokens: 100, Latency: time.Second}
	results := []Result{
		{Case: Case{ID: "a", WantIntent: comments.IntentLead, WantPass: true}, Review: ok},                                    // right
		{Case: Case{ID: "b", WantIntent: comments.IntentLead, WantPass: false}, Review: ok},                                   // false send
		{Case: Case{ID: "c", WantIntent: comments.IntentLead, WantPass: true}, Err: errors.New("timeout")},                    // error: missed
		{Case: Case{ID: "d", WantIntent: comments.IntentComplaint, WantPass: false}, Review: comments.Review{Intent: "lead"}}, // right decision, wrong intent
	}

	// Act
	s := Summarize("x", results, Price{In: 1, Out: 10}, true)

	// Assert
	if s.Cases != 4 || s.Errors != 1 || s.FalseSends != 1 || s.MissedSends != 1 || s.DecisionAcc != 0.5 {
		t.Fatalf("summary %+v", s)
	}
	if math.Abs(s.IntentAcc-2.0/3) > 1e-9 || s.FalseSendCases[0] != "b" {
		t.Fatalf("intent %v false %v", s.IntentAcc, s.FalseSendCases)
	}
	// avg 2000/3 in, 200/3 out tokens; $1 and $10 per M → per 1000 comments
	want := (2000.0/3*1 + 200.0/3*10) / 1e6 * 1000
	if math.Abs(s.CostPer1000-want) > 1e-9 {
		t.Fatalf("cost %v want %v", s.CostPer1000, want)
	}
}

func TestPercentile(t *testing.T) {
	// Arrange
	d := []time.Duration{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}

	// Act / Assert
	if percentile(d, 0.5) != 5 || percentile(d, 0.95) != 10 || percentile(nil, 0.5) != 0 {
		t.Fatal("percentile wrong")
	}
}

func TestSafeURL(t *testing.T) {
	for raw, ok := range map[string]bool{
		"https://api.openai.com/v1": true, "http://127.0.0.1:8080/v1": true, "http://localhost:1/v1": true,
		"http://api.example.com/v1": false, "ftp://x": false, "not a url": false,
	} {
		// Act / Assert
		if err := safeURL(raw); (err == nil) != ok {
			t.Errorf("%s: err %v", raw, err)
		}
	}
}

func TestSplitIsBalancedAndStable(t *testing.T) {
	// Arrange
	cases, _ := loadCases("../../testdata/comment-eval/cases.jsonl")
	results := make([]Result, len(cases))
	for i, c := range cases {
		results[i] = Result{Case: c}
	}

	// Act
	tune1, test1 := Split(results)
	tune2, _ := Split(results)

	// Assert
	count := func(rs []Result) (n int) {
		for _, r := range rs {
			if r.Case.WantPass {
				n++
			}
		}
		return n
	}
	if len(tune1)+len(test1) != len(cases) || tune1[0].Case.ID != tune2[0].Case.ID {
		t.Fatal("split lost cases or is not stable")
	}
	if d := count(tune1) - count(test1); d < -1 || d > 1 {
		t.Fatalf("unbalanced: %d vs %d passing", count(tune1), count(test1))
	}
}

func TestTune_NeverTradesAFalseSendForAccuracy(t *testing.T) {
	// Arrange: a good draft scored 0.85 on offer, and a bad one scored 0.80
	mk := func(id string, offer float64, want bool) Result {
		return Result{Case: Case{ID: id, Draft: "สวัสดีค่ะ", WantPass: want, WantIntent: comments.IntentLead},
			Review: comments.Review{Intent: comments.IntentLead, PIntent: map[comments.Intent]float64{comments.IntentLead: 1},
				Checks: map[string]float64{comments.CheckAnswersComment: 1, comments.CheckNoUnbackedOffer: offer, comments.CheckToneFits: 1, comments.CheckGenuine: 1}}}
	}
	results := []Result{mk("good", 0.85, true), mk("bad", 0.80, false)}

	// Act
	best := Tune(results, comments.LLMThresholds)

	// Assert: the bar drops to let 0.85 through, but stays above 0.80
	fs, right := score(Redecide(results, best))
	if fs != 0 || right != 2 || best.Offer <= 0.80 || best.Offer > 0.85 {
		t.Fatalf("best %+v fs %d right %d", best, fs, right)
	}
}
