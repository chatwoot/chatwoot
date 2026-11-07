// Package answereval grades the bot's real replies, end to end: business
// profile, knowledge search, query rewrite and the chat model, over
// multi-turn test conversations. Each case is checked by hard rules first
// (handoff, required and forbidden text), then by an LLM judge that looks for
// wrong answers and invented business facts. The judge also scores two RAG
// metrics: faithfulness (every business claim in the reply is backed by the
// profile or the excerpts) and context recall (the profile and excerpts held
// what a correct answer needs). Recall separates retrieval misses from
// generation mistakes.
package answereval

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/bot"
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
	// Files go with the last turn, as a customer's attachments: voice
	// notes, photos, stickers or other files. Paths are relative to the
	// cases file; the last turn's text may be "".
	Files   []string     `json:"files"`
	Uploads []bot.Upload `json:"-"` // Files' contents, filled by LoadFiles
}

// maxCaseFiles matches what one customer message can carry in the test chat.
const maxCaseFiles = 4

// Answerer produces the bot's reply for a conversation (bot.Bot.Answer).
type Answerer interface {
	Answer(ctx context.Context, acct, inbox int64, history []memory.Turn) (llm.Result, []knowledge.Hit, error)
}

// MediaAnswerer answers a last turn that has files (bot.Bot.PreviewMedia),
// with the same media handling, keyword handoff and handoff marker as live.
type MediaAnswerer interface {
	PreviewMedia(ctx context.Context, acct, inbox int64, history []memory.Turn, uploads []bot.Upload) bot.Preview
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
	// LastInput is the last message as the bot read it, when files came
	// with it: typed text, the voice transcript and file notes.
	LastInput string
}

// Verdict is the judge's decision. The metrics are nil when the judge did
// not score them (context recall is only scored for expected answers).
type Verdict struct {
	Pass          bool   `json:"pass"`
	Reason        string `json:"reason"`
	Faithful      *bool  `json:"faithful,omitempty"`
	ContextRecall *bool  `json:"context_recall,omitempty"`
}

// Judge grades one reply.
type Judge interface {
	Judge(ctx context.Context, in JudgeInput) (Verdict, error)
}

// Runner holds what a run needs.
type Runner struct {
	Answerer Answerer
	Media    MediaAnswerer // needed for cases with files
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
	// RAG metrics from the judge; nil when not scored.
	Faithful      *bool
	ContextRecall *bool
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
		if len(c.Files) > maxCaseFiles {
			errs = append(errs, fmt.Errorf("%s: at most %d files", name, maxCaseFiles))
		}
		switch c.Expect {
		case ExpectAnswer, ExpectUnknown, ExpectHandoff:
		default:
			errs = append(errs, fmt.Errorf("%s: expect must be answer, unknown or handoff, not %q", name, c.Expect))
		}
	}
	return errors.Join(errs...)
}

// LoadFiles reads every case's files from dir, the cases file's folder.
// Paths must stay inside dir.
func LoadFiles(cases []Case, dir string) error {
	root, err := os.OpenRoot(dir)
	if err != nil {
		return err
	}
	defer func() { _ = root.Close() }()
	var errs []error
	for i := range cases {
		for _, f := range cases[i].Files {
			data, err := root.ReadFile(f)
			if err != nil {
				errs = append(errs, fmt.Errorf("%s: %w", cases[i].Name, err))
				continue
			}
			cases[i].Uploads = append(cases[i].Uploads, bot.Upload{Name: filepath.Base(f), Data: data})
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
	var lastInput string
	for i, turn := range c.Turns {
		history = append(history, memory.Turn{Role: "user", Content: turn})
		if i == len(c.Turns)-1 && len(c.Uploads) > 0 {
			if r.Media == nil {
				res.Err = errors.New("no media answerer")
				res.Reason = "case has files but the runner cannot send them"
				return res
			}
			p := r.Media.PreviewMedia(ctx, c.AccountID, c.InboxID, history, c.Uploads)
			if p.Err != nil {
				res.Err, res.Reason = p.Err, "answer failed: "+p.Err.Error()
				return res
			}
			res.Reply, res.Handoff, hits, lastInput = p.Reply, p.Handoff, p.Sources, p.Input
			break
		}
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
	in := JudgeInput{Case: c, Reply: res.Reply, Excerpts: excerpts, LastInput: lastInput}
	if r.Profile != nil {
		in.Profile = r.Profile(ctx, c.AccountID)
	}
	v, err := r.Judge.Judge(ctx, in)
	if err != nil {
		res.Err, res.Reason = err, "judge failed: "+err.Error()
		return res
	}
	res.Pass, res.Reason = v.Pass, v.Reason
	res.Faithful, res.ContextRecall = v.Faithful, v.ContextRecall
	// An unsupported claim always fails, whatever the judge's pass says.
	if v.Faithful != nil && !*v.Faithful && res.Pass {
		res.Pass = false
		res.Reason = "reply makes a claim not supported by the profile or excerpts: " + v.Reason
	}
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
			if res.ContextRecall != nil && !*res.ContextRecall {
				fmt.Fprintln(w, "     cause: retrieval: the context lacked what the answer needs")
			}
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
	writeMetrics(w, r.Results)
}

// writeMetrics prints the RAG metric totals over the cases the judge scored.
func writeMetrics(w io.Writer, results []Result) {
	var faithful, recall [2]int // [true, scored]
	for _, res := range results {
		count(&faithful, res.Faithful)
		count(&recall, res.ContextRecall)
	}
	var parts []string
	if faithful[1] > 0 {
		parts = append(parts, fmt.Sprintf("faithful %d/%d", faithful[0], faithful[1]))
	}
	if recall[1] > 0 {
		parts = append(parts, fmt.Sprintf("context recall %d/%d", recall[0], recall[1]))
	}
	if len(parts) > 0 {
		fmt.Fprintln(w, "RAG: "+strings.Join(parts, " · "))
	}
}

func count(t *[2]int, v *bool) {
	if v == nil {
		return
	}
	t[1]++
	if *v {
		t[0]++
	}
}

func oneLine(s string) string {
	s = strings.Join(strings.Fields(s), " ")
	if r := []rune(s); len(r) > 200 {
		return string(r[:200]) + "…"
	}
	return s
}
