package answereval

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/bot"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/llm"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/memory"
)

type scriptedAnswerer struct {
	replies   []string
	histories [][]memory.Turn
	err       error
}

func (s *scriptedAnswerer) Answer(_ context.Context, _, _ int64, h []memory.Turn) (llm.Result, []knowledge.Hit, error) {
	s.histories = append(s.histories, append([]memory.Turn(nil), h...))
	if s.err != nil {
		return llm.Result{}, nil, s.err
	}
	r := s.replies[0]
	s.replies = s.replies[1:]
	return llm.Result{Content: r}, []knowledge.Hit{{Content: "ราคา 3,900 บาท"}}, nil
}

type keyword string

func (k keyword) Wants(text string) bool { return strings.Contains(text, string(k)) }

type fixedJudge struct {
	verdict Verdict
	calls   int
	got     JudgeInput
}

func (f *fixedJudge) Judge(_ context.Context, in JudgeInput) (Verdict, error) {
	f.calls++
	f.got = in
	return f.verdict, nil
}

func TestCheckRules(t *testing.T) {
	cases := map[string]struct {
		c     Case
		reply string
		fails int
	}{
		"alternatives match":   {Case{MustInclude: []string{"3,900|3900"}}, "ราคา 3900 บาทค่ะ", 0},
		"missing required":     {Case{MustInclude: []string{"30 พฤศจิกายน|30 พ.ย."}}, "ถึงสิ้นเดือนค่ะ", 1},
		"forbidden present":    {Case{MustNotInclude: []string{"ฟรี"}}, "คอร์สฟรีค่ะ", 1},
		"case-insensitive":     {Case{MustInclude: []string{"line"}}, "ทัก LINE ได้เลย", 0},
		"several failures add": {Case{MustInclude: []string{"a", "b"}, MustNotInclude: []string{"c"}}, "c", 3},
	}
	for name, tc := range cases {
		t.Run(name, func(t *testing.T) {
			// Act
			got := checkRules(tc.c, tc.reply)

			// Assert
			if len(got) != tc.fails {
				t.Errorf("checkRules() = %q, want %d failures", got, tc.fails)
			}
		})
	}
}

func TestParseVerdict(t *testing.T) {
	// Arrange
	raw := "Here you go:\n```json\n{\"pass\": false, \"reason\": \"invented a refund window\"}\n```"

	// Act
	v, err := parseVerdict(raw)

	// Assert
	if err != nil || v.Pass || v.Reason != "invented a refund window" {
		t.Fatalf("parseVerdict() = %+v, %v", v, err)
	}
	if _, err := parseVerdict("no json here"); err == nil {
		t.Error("parseVerdict(no json) = nil error, want an error")
	}
}

func TestRunMultiTurnGradesLastReply(t *testing.T) {
	// Arrange
	a := &scriptedAnswerer{replies: []string{"3,900 บาทค่ะ", "ถึง 30 พฤศจิกายนค่ะ"}}
	j := &fixedJudge{verdict: Verdict{Pass: true, Reason: "ok"}}
	c := Case{Name: "promo", Turns: []string{"ราคาเท่าไหร่", "โปรถึงวันไหน"}, Expect: ExpectAnswer, MustInclude: []string{"30 พฤศจิกายน"}}

	// Act
	profileFor := func(_ context.Context, acct int64) string { return fmt.Sprintf("profile of %d", acct) }
	c.AccountID = 3
	rep := Run(context.Background(), Runner{Answerer: a, Handoff: keyword("แอดมิน"), Judge: j, Profile: profileFor}, []Case{c})

	// Assert
	r := rep.Results[0]
	if j.got.Profile != "profile of 3" {
		t.Errorf("judge profile = %q, want account 3's", j.got.Profile)
	}
	if !r.Pass || r.Reply != "ถึง 30 พฤศจิกายนค่ะ" || rep.Passed != 1 {
		t.Fatalf("result = %+v", r)
	}
	if len(a.histories[1]) != 3 || a.histories[1][1].Role != "assistant" {
		t.Errorf("second turn history = %+v, want user/assistant/user", a.histories[1])
	}
	if j.got.Reply != r.Reply || len(j.got.Excerpts) != 1 {
		t.Errorf("judge input = %+v", j.got)
	}
}

func TestRunRuleFailureSkipsJudge(t *testing.T) {
	// Arrange
	j := &fixedJudge{verdict: Verdict{Pass: true}}
	c := Case{Name: "price", Turns: []string{"ราคา"}, Expect: ExpectAnswer, MustInclude: []string{"3,900"}}

	// Act
	rep := Run(context.Background(), Runner{Answerer: &scriptedAnswerer{replies: []string{"ไม่ทราบค่ะ"}}, Handoff: keyword("แอดมิน"), Judge: j}, []Case{c})

	// Assert
	if rep.Results[0].Pass || j.calls != 0 {
		t.Errorf("pass = %v, judge calls = %d; want a fail without judging", rep.Results[0].Pass, j.calls)
	}
}

func TestRunHandoff(t *testing.T) {
	// Arrange
	a := &scriptedAnswerer{replies: []string{"unused"}}
	j := &fixedJudge{}
	cases := []Case{
		{Name: "asks for staff", Turns: []string{"ขอคุยกับแอดมิน"}, Expect: ExpectHandoff},
		{Name: "unexpected handoff", Turns: []string{"แอดมินอยู่ไหม"}, Expect: ExpectAnswer},
	}

	// Act
	rep := Run(context.Background(), Runner{Answerer: a, Handoff: keyword("แอดมิน"), Judge: j}, cases)

	// Assert
	if !rep.Results[0].Pass || rep.Results[1].Pass {
		t.Errorf("results = %+v / %+v; want pass then fail", rep.Results[0], rep.Results[1])
	}
	if len(a.histories) != 0 || j.calls != 0 {
		t.Error("a handoff must not call the model or the judge")
	}
}

func TestRunAnswerErrorFails(t *testing.T) {
	// Act
	rep := Run(context.Background(), Runner{Answerer: &scriptedAnswerer{err: errors.New("down")}, Handoff: keyword("x"), Judge: &fixedJudge{}},
		[]Case{{Name: "e", Turns: []string{"hi"}, Expect: ExpectAnswer}})

	// Assert
	if rep.Results[0].Pass || rep.Results[0].Err == nil {
		t.Fatalf("result = %+v, want a failure with the error", rep.Results[0])
	}
}

func TestValidateCases(t *testing.T) {
	// Arrange
	bad := []Case{{Name: "no turns", AccountID: 1, Expect: ExpectAnswer}, {Name: "bad expect", AccountID: 1, Turns: []string{"x"}, Expect: "maybe"},
		{Name: "no account", Turns: []string{"x"}, Expect: ExpectAnswer}}

	// Act
	err := Validate(bad)

	// Assert
	if err == nil || !strings.Contains(err.Error(), "no turns") || !strings.Contains(err.Error(), "bad expect") || !strings.Contains(err.Error(), "no account") {
		t.Fatalf("Validate() = %v", err)
	}
}

func TestReportWrite(t *testing.T) {
	// Arrange
	rep := Report{Results: []Result{{Case: Case{Name: "a", Expect: ExpectAnswer}, Pass: true}, {Case: Case{Name: "b", Expect: ExpectUnknown}, Reason: "invented price"}}, Passed: 1}
	var buf bytes.Buffer

	// Act
	rep.Write(&buf)

	// Assert
	out := buf.String()
	for _, want := range []string{"PASS a", "FAIL b", "invented price", "1/2"} {
		if !strings.Contains(out, want) {
			t.Errorf("report is missing %q:\n%s", want, out)
		}
	}
}

func TestReportVerbosePrintsPassingReplies(t *testing.T) {
	// Arrange
	rep := Report{Verbose: true, Passed: 1, Results: []Result{{Case: Case{Name: "a", Expect: ExpectAnswer}, Pass: true, Reply: "3,900 บาทค่ะ"}}}
	var buf bytes.Buffer

	// Act
	rep.Write(&buf)

	// Assert
	if !strings.Contains(buf.String(), "3,900 บาทค่ะ") {
		t.Errorf("verbose report is missing the reply:\n%s", buf.String())
	}
}

func TestRunModelHandoffMarker(t *testing.T) {
	// Arrange: the model asks for a person on the first turn; the second turn never runs.
	a := &scriptedAnswerer{replies: []string{"[[H]] staff will check your slip"}}
	split := func(r string) (string, bool) { return strings.TrimPrefix(r, "[[H]] "), strings.HasPrefix(r, "[[H]]") }
	cases := []Case{{Name: "slip", Turns: []string{"โอนแล้วค่ะ", "เช็คให้หน่อย"}, Expect: ExpectHandoff}}

	// Act
	rep := Run(context.Background(), Runner{Answerer: a, Handoff: keyword("แอดมิน"), Judge: &fixedJudge{}, Split: split}, cases)

	// Assert
	r := rep.Results[0]
	if !r.Pass || !r.Handoff || r.Reply != "staff will check your slip" || len(a.histories) != 1 {
		t.Fatalf("result = %+v, calls = %d", r, len(a.histories))
	}
}

func TestRunUnknownMayHandOff(t *testing.T) {
	// Arrange
	a := &scriptedAnswerer{replies: []string{"[[H]] staff will answer that"}}
	split := func(r string) (string, bool) { return strings.TrimPrefix(r, "[[H]] "), strings.HasPrefix(r, "[[H]]") }
	j := &fixedJudge{verdict: Verdict{Pass: true}}

	// Act
	rep := Run(context.Background(), Runner{Answerer: a, Handoff: keyword("x"), Judge: j, Split: split},
		[]Case{{Name: "u", Turns: []string{"python course?"}, Expect: ExpectUnknown}})

	// Assert
	if !rep.Results[0].Pass || j.calls != 1 {
		t.Errorf("result = %+v, judge calls = %d; want a pass after judging the text", rep.Results[0], j.calls)
	}
}

type fakeCompleter struct{ reply string }

func (f fakeCompleter) Complete(_ context.Context, _ []llm.Message) (llm.Result, error) {
	return llm.Result{Content: f.reply}, nil
}

func TestParseVerdictMetrics(t *testing.T) {
	// Arrange
	withMetrics := `{"pass": true, "reason": "ok", "faithful": true, "context_recall": false}`
	without := `{"pass": true, "reason": "ok"}`

	// Act
	v, err := parseVerdict(withMetrics)
	bare, bareErr := parseVerdict(without)

	// Assert
	if err != nil || v.Faithful == nil || !*v.Faithful || v.ContextRecall == nil || *v.ContextRecall {
		t.Fatalf("parseVerdict(metrics) = %+v, %v", v, err)
	}
	if bareErr != nil || bare.Faithful != nil || bare.ContextRecall != nil {
		t.Errorf("parseVerdict(no metrics) = %+v, %v; want nil metrics", bare, bareErr)
	}
}

func TestLLMJudgeAsksForMetrics(t *testing.T) {
	// Arrange
	j := LLMJudge{LLM: fakeCompleter{reply: `{"pass": true, "reason": "ok", "faithful": true, "context_recall": true}`}}

	// Act
	v, err := j.Judge(context.Background(), JudgeInput{Case: Case{Expect: ExpectAnswer}, Reply: "3,900 บาทค่ะ"})

	// Assert
	if err != nil || v.Faithful == nil || v.ContextRecall == nil {
		t.Fatalf("Judge() = %+v, %v", v, err)
	}
	for _, want := range []string{`"faithful"`, `"context_recall"`} {
		if !strings.Contains(judgeInstruction, want) {
			t.Errorf("judge instruction does not ask for %s", want)
		}
	}
}

func TestRunUnfaithfulReplyFails(t *testing.T) {
	// Arrange: the judge passes the reply but marks it unfaithful to the context.
	no := false
	j := &fixedJudge{verdict: Verdict{Pass: true, Reason: "answers the question", Faithful: &no}}
	c := Case{Name: "price", AccountID: 1, Turns: []string{"ราคา"}, Expect: ExpectAnswer}

	// Act
	rep := Run(context.Background(), Runner{Answerer: &scriptedAnswerer{replies: []string{"3,900 บาท ผ่อนได้ 10 เดือน"}}, Handoff: keyword("แอดมิน"), Judge: j}, []Case{c})

	// Assert
	r := rep.Results[0]
	if r.Pass || rep.Passed != 0 || !strings.Contains(r.Reason, "not supported") {
		t.Fatalf("result = %+v, want a fail for an unsupported claim", r)
	}
	if r.Faithful == nil || *r.Faithful {
		t.Errorf("result faithful = %v, want false", r.Faithful)
	}
}

func TestRunKeepsContextRecall(t *testing.T) {
	// Arrange
	no := false
	j := &fixedJudge{verdict: Verdict{Pass: false, Reason: "does not give the date", ContextRecall: &no}}
	c := Case{Name: "promo", AccountID: 1, Turns: []string{"โปรถึงวันไหน"}, Expect: ExpectAnswer}

	// Act
	rep := Run(context.Background(), Runner{Answerer: &scriptedAnswerer{replies: []string{"ไม่แน่ใจค่ะ"}}, Handoff: keyword("แอดมิน"), Judge: j}, []Case{c})

	// Assert
	if r := rep.Results[0]; r.ContextRecall == nil || *r.ContextRecall || r.Pass {
		t.Fatalf("result = %+v, want a fail with context recall false", r)
	}
}

func TestReportWriteMetrics(t *testing.T) {
	// Arrange
	yes, no := true, false
	rep := Report{Passed: 1, Results: []Result{
		{Case: Case{Name: "a", Expect: ExpectAnswer}, Pass: true, Faithful: &yes, ContextRecall: &yes},
		{Case: Case{Name: "b", Expect: ExpectAnswer}, Reason: "no date", Faithful: &yes, ContextRecall: &no},
		{Case: Case{Name: "c", Expect: ExpectHandoff}, Pass: false, Reason: "did not hand off"},
	}}
	var buf bytes.Buffer

	// Act
	rep.Write(&buf)

	// Assert
	out := buf.String()
	for _, want := range []string{"faithful 2/2", "context recall 1/2", "retrieval: the context lacked what the answer needs"} {
		if !strings.Contains(out, want) {
			t.Errorf("report is missing %q:\n%s", want, out)
		}
	}
}

func TestReportWriteOmitsMetricsWhenNoneGraded(t *testing.T) {
	// Arrange
	rep := Report{Results: []Result{{Case: Case{Name: "c", Expect: ExpectHandoff}, Pass: true}}, Passed: 1}
	var buf bytes.Buffer

	// Act
	rep.Write(&buf)

	// Assert
	if strings.Contains(buf.String(), "faithful") || strings.Contains(buf.String(), "context recall") {
		t.Errorf("report prints metrics nobody graded:\n%s", buf.String())
	}
}

type fakeMedia struct {
	out     bot.Preview
	history []memory.Turn
	uploads []bot.Upload
}

func (f *fakeMedia) PreviewMedia(_ context.Context, _, _ int64, h []memory.Turn, u []bot.Upload) bot.Preview {
	f.history, f.uploads = append([]memory.Turn(nil), h...), u
	return f.out
}

func TestRunFilesGoToLastTurn(t *testing.T) {
	// Arrange: a text turn, then a voice note with no text.
	a := &scriptedAnswerer{replies: []string{"สวัสดีค่ะ"}}
	m := &fakeMedia{out: bot.Preview{Reply: "ผ่อนได้ 10 เดือนค่ะ", Input: "[Voice message, transcribed] ผ่อนได้ไหม",
		Sources: []knowledge.Hit{{Content: "ผ่อน 10 เดือน"}}}}
	j := &fixedJudge{verdict: Verdict{Pass: true}}
	c := Case{Name: "voice", AccountID: 1, Turns: []string{"สวัสดี", ""}, Expect: ExpectAnswer,
		Files: []string{"voice.ogg"}, Uploads: []bot.Upload{{Name: "voice.ogg", Data: []byte("OggS")}}}

	// Act
	rep := Run(context.Background(), Runner{Answerer: a, Media: m, Handoff: keyword("แอดมิน"), Judge: j}, []Case{c})

	// Assert
	r := rep.Results[0]
	if !r.Pass || r.Reply != "ผ่อนได้ 10 เดือนค่ะ" || len(a.histories) != 1 || len(m.uploads) != 1 || len(m.history) != 3 {
		t.Fatalf("result = %+v, text answers = %d, media history = %d", r, len(a.histories), len(m.history))
	}
	if j.got.LastInput != "[Voice message, transcribed] ผ่อนได้ไหม" || len(j.got.Excerpts) != 1 {
		t.Errorf("judge input = %+v", j.got)
	}
	if !strings.Contains(judgePrompt(j.got), "ผ่อนได้ไหม") {
		t.Error("judge prompt does not show the transcript")
	}
}

func TestRunMediaHandoffAndError(t *testing.T) {
	// Arrange
	handoff := &fakeMedia{out: bot.Preview{Reply: "thanks", Handoff: true, Reason: bot.ReasonAttachment}}
	failing := &fakeMedia{out: bot.Preview{Reply: "sorry", Handoff: true, Reason: bot.ReasonLLMError, Err: errors.New("down")}}
	c := Case{Name: "pdf", AccountID: 1, Turns: []string{""}, Expect: ExpectHandoff, Files: []string{"a.pdf"}, Uploads: []bot.Upload{{Name: "a.pdf"}}}

	// Act
	ok := Run(context.Background(), Runner{Answerer: &scriptedAnswerer{}, Media: handoff, Handoff: keyword("x"), Judge: &fixedJudge{}}, []Case{c})
	bad := Run(context.Background(), Runner{Answerer: &scriptedAnswerer{}, Media: failing, Handoff: keyword("x"), Judge: &fixedJudge{}}, []Case{c})

	// Assert
	if !ok.Results[0].Pass || !ok.Results[0].Handoff {
		t.Errorf("attachment handoff result = %+v, want a pass", ok.Results[0])
	}
	if bad.Results[0].Pass || bad.Results[0].Err == nil {
		t.Errorf("model error result = %+v, want a fail with the error", bad.Results[0])
	}
}

func TestLoadFiles(t *testing.T) {
	// Arrange
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, "voice.ogg"), []byte("OggS"), 0o600); err != nil {
		t.Fatal(err)
	}
	cases := []Case{{Name: "ok", Files: []string{"voice.ogg"}}, {Name: "none"}}
	missing := []Case{{Name: "gone", Files: []string{"nope.ogg"}}}
	escape := []Case{{Name: "up", Files: []string{"../secret"}}}

	// Act
	err := LoadFiles(cases, dir)
	errMissing := LoadFiles(missing, dir)
	errEscape := LoadFiles(escape, dir)

	// Assert
	if err != nil || len(cases[0].Uploads) != 1 || string(cases[0].Uploads[0].Data) != "OggS" || cases[1].Uploads != nil {
		t.Fatalf("LoadFiles() = %v, cases = %+v", err, cases)
	}
	if errMissing == nil || !strings.Contains(errMissing.Error(), "gone") {
		t.Errorf("missing file error = %v", errMissing)
	}
	if errEscape == nil {
		t.Error("a path outside the cases folder was read")
	}
}

func TestValidateFilesNeedLastTurn(t *testing.T) {
	// Arrange: files with too many entries for the bot to read.
	c := []Case{{Name: "many", AccountID: 1, Turns: []string{"x"}, Expect: ExpectAnswer, Files: []string{"1", "2", "3", "4", "5"}}}

	// Act
	err := Validate(c)

	// Assert
	if err == nil || !strings.Contains(err.Error(), "files") {
		t.Fatalf("Validate() = %v", err)
	}
}
