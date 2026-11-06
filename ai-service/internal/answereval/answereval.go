// Package answereval grades the bot's real replies, end to end: business
// profile, knowledge search, query rewrite and the chat model, over
// multi-turn test conversations. Each case is checked by hard rules first
// (handoff, required and forbidden text), then by an LLM judge that looks for
// wrong answers and invented business facts.
package answereval

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"strings"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/llm"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/memory"
)

// What a correct last reply does.
const (
	ExpectAnswer  = "answer"  // answers from the knowledge base
	ExpectUnknown = "unknown" // says it does not know and offers staff, invents nothing
	ExpectHandoff = "handoff" // the customer asked for a person
)

// Case is one test conversation. Only the reply to the last turn is graded.
type Case struct {
	Name      string   `json:"name"`
	AccountID int64    `json:"account_id"`
	InboxID   int64    `json:"inbox_id"`
	Turns     []string `json:"turns"`
	Expect    string   `json:"expect"`
	// Every entry must appear in the reply; "a|b" accepts either.
	MustInclude    []string `json:"must_include"`
	MustNotInclude []string `json:"must_not_include"`
	// Note tells the judge what a correct reply says.
	Note string `json:"note"`
}

// Answerer produces the bot's reply for a conversation (bot.Bot.Answer).
type Answerer interface {
	Answer(ctx context.Context, acct, inbox int64, history []memory.Turn) (llm.Result, []knowledge.Hit, error)
}

// HandoffDetector reports whether a customer message asks for a person.
type HandoffDetector interface {
	Wants(text string) bool
}

// JudgeInput is what the judge sees.
type JudgeInput struct {
	Case     Case
	Reply    string
	Excerpts []string
	Profile  string // the business profile the bot was given, if any
}

// Verdict is the judge's decision.
type Verdict struct {
	Pass   bool   `json:"pass"`
	Reason string `json:"reason"`
}

// Judge grades one reply.
type Judge interface {
	Judge(ctx context.Context, in JudgeInput) (Verdict, error)
}

// Runner holds what a run needs.
type Runner struct {
	Answerer Answerer
	Handoff  HandoffDetector
	Judge    Judge
	// Profile returns the account's business profile text; optional.
	Profile func(ctx context.Context, acct int64) string
	// Split removes the model's handoff marker and reports it; optional.
	Split func(reply string) (string, bool)
}

// Result is the outcome of one case.
type Result struct {
	Case    Case
	Reply   string
	Handoff bool
	Pass    bool
	Reason  string
	Err     error
}

// Report summarises a run.
type Report struct {
	Results []Result
	Passed  int
	Verbose bool // also print the reply of passing cases
}

// Validate checks a cases file before anything is spent on model calls.
func Validate(cases []Case) error {
	var errs []error
	for i, c := range cases {
		name := c.Name
		if name == "" {
			name = fmt.Sprintf("#%d", i+1)
		}
		if c.AccountID < 1 {
			errs = append(errs, fmt.Errorf("%s: no account_id", name))
		}
		if len(c.Turns) == 0 {
			errs = append(errs, fmt.Errorf("%s: no turns", name))
		}
		switch c.Expect {
		case ExpectAnswer, ExpectUnknown, ExpectHandoff:
		default:
			errs = append(errs, fmt.Errorf("%s: expect must be answer, unknown or handoff, not %q", name, c.Expect))
		}
	}
	return errors.Join(errs...)
}

// Run plays every case and grades the last reply.
func Run(ctx context.Context, r Runner, cases []Case) Report {
	var rep Report
	for _, c := range cases {
		res := r.runCase(ctx, c)
		if res.Pass {
			rep.Passed++
		}
		rep.Results = append(rep.Results, res)
	}
	return rep
}

func (r Runner) runCase(ctx context.Context, c Case) Result {
	res := Result{Case: c}
	var history []memory.Turn
	var hits []knowledge.Hit
	for _, turn := range c.Turns {
		history = append(history, memory.Turn{Role: "user", Content: turn})
		if r.Handoff.Wants(turn) {
			res.Handoff = true
			break
		}
		out, h, err := r.Answerer.Answer(ctx, c.AccountID, c.InboxID, history)
		if err != nil {
			res.Err, res.Reason = err, "answer failed: "+err.Error()
			return res
		}
		res.Reply, hits = out.Content, h
		if r.Split != nil {
			res.Reply, res.Handoff = r.Split(out.Content)
		}
		history = append(history, memory.Turn{Role: "assistant", Content: res.Reply})
		if res.Handoff {
			break
		}
	}

	// Handing off is also a correct way to not know, if the text invents nothing.
	if c.Expect == ExpectHandoff || (res.Handoff && c.Expect != ExpectUnknown) {
		res.Pass = c.Expect == ExpectHandoff && res.Handoff
		if !res.Pass {
			res.Reason = map[bool]string{true: "handed off unexpectedly", false: "did not hand off"}[res.Handoff]
		}
		return res
	}
	if fails := checkRules(c, res.Reply); len(fails) > 0 {
		res.Reason = strings.Join(fails, "; ")
		return res
	}
	excerpts := make([]string, len(hits))
	for i, h := range hits {
		excerpts[i] = h.Content
	}
	in := JudgeInput{Case: c, Reply: res.Reply, Excerpts: excerpts}
	if r.Profile != nil {
		in.Profile = r.Profile(ctx, c.AccountID)
	}
	v, err := r.Judge.Judge(ctx, in)
	if err != nil {
		res.Err, res.Reason = err, "judge failed: "+err.Error()
		return res
	}
	res.Pass, res.Reason = v.Pass, v.Reason
	return res
}

// checkRules returns one message per broken rule.
func checkRules(c Case, reply string) []string {
	text := strings.ToLower(reply)
	var fails []string
	for _, want := range c.MustInclude {
		found := false
		for _, alt := range strings.Split(want, "|") {
			if alt = strings.ToLower(strings.TrimSpace(alt)); alt != "" && strings.Contains(text, alt) {
				found = true
				break
			}
		}
		if !found {
			fails = append(fails, fmt.Sprintf("missing %q", want))
		}
	}
	for _, bad := range c.MustNotInclude {
		if strings.Contains(text, strings.ToLower(bad)) {
			fails = append(fails, fmt.Sprintf("contains forbidden %q", bad))
		}
	}
	return fails
}

// parseVerdict reads the first JSON object in the judge's reply.
func parseVerdict(raw string) (Verdict, error) {
	start, end := strings.Index(raw, "{"), strings.LastIndex(raw, "}")
	if start < 0 || end <= start {
		return Verdict{}, errors.New("judge reply has no JSON object")
	}
	var v Verdict
	if err := json.Unmarshal([]byte(raw[start:end+1]), &v); err != nil {
		return Verdict{}, fmt.Errorf("judge reply: %w", err)
	}
	return v, nil
}

// Write prints one line per case and the totals by expectation.
func (r Report) Write(w io.Writer) {
	type tally struct{ pass, total int }
	by := map[string]*tally{}
	for _, res := range r.Results {
		mark := "FAIL"
		if res.Pass {
			mark = "PASS"
		}
		fmt.Fprintf(w, "%s %s [%s]\n", mark, res.Case.Name, res.Case.Expect)
		if !res.Pass {
			fmt.Fprintf(w, "     why:   %s\n", res.Reason)
		}
		if !res.Pass || r.Verbose {
			fmt.Fprintf(w, "     reply: %s\n", oneLine(res.Reply))
		}
		t := by[res.Case.Expect]
		if t == nil {
			t = &tally{}
			by[res.Case.Expect] = t
		}
		t.total++
		if res.Pass {
			t.pass++
		}
	}
	fmt.Fprintf(w, "\nPassed %d/%d", r.Passed, len(r.Results))
	for _, e := range []string{ExpectAnswer, ExpectUnknown, ExpectHandoff} {
		if t := by[e]; t != nil {
			fmt.Fprintf(w, " · %s %d/%d", e, t.pass, t.total)
		}
	}
	fmt.Fprintln(w)
}

func oneLine(s string) string {
	s = strings.Join(strings.Fields(s), " ")
	if r := []rune(s); len(r) > 200 {
		return string(r[:200]) + "…"
	}
	return s
}
