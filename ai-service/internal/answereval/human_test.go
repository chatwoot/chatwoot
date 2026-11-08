package answereval

import (
	"context"
	"strings"
	"testing"
	"time"
)

func TestRunHistoryIsGivenNotGenerated(t *testing.T) {
	// Arrange
	a := &scriptedAnswerer{replies: []string{"ไลฟ์ยาวกี่ชั่วโมงครับ"}}
	j := &fixedJudge{verdict: Verdict{Pass: true}}
	c := Case{Name: "m01", AccountID: 1, Expect: ExpectAnswer,
		History: []Message{{Role: "user", Content: "ราคาเท่าไหร่"}, {Role: "assistant", Content: "3,900 บาทครับ"}},
		Turns:   []string{"ขายเสื้อผ้า ไลฟ์ทุกวัน"}}

	// Act
	rep := Run(context.Background(), Runner{Answerer: a, Handoff: keyword("แอดมิน"), Judge: j}, []Case{c})

	// Assert
	if len(a.histories) != 1 || len(a.histories[0]) != 3 || a.histories[0][1].Role != "assistant" {
		t.Fatalf("model saw %+v, want the given history plus the last turn, answered once", a.histories)
	}
	if !rep.Results[0].Pass {
		t.Fatalf("result = %+v", rep.Results[0])
	}
}

func TestValidateHistory(t *testing.T) {
	// Arrange
	bad := []Case{
		{Name: "role", AccountID: 1, Expect: ExpectAnswer, Turns: []string{"x"}, History: []Message{{Role: "system", Content: "x"}}},
		{Name: "empty", AccountID: 1, Expect: ExpectAnswer, Turns: []string{"x"}, History: []Message{{Role: "user"}}},
	}

	// Act
	err := Validate(bad)

	// Assert
	if err == nil || !strings.Contains(err.Error(), "role") || !strings.Contains(err.Error(), "empty") {
		t.Fatalf("Validate() = %v, want errors for both cases", err)
	}
}

func TestCheckStyle(t *testing.T) {
	cases := map[string]struct {
		c     Case
		reply string
		fails int
	}{
		"short plain":     {Case{MaxLines: 6, NoMarkdown: true}, "ราคา 3,900 บาทครับ\nทำคลิปแนวไหนครับ", 0},
		"too many lines":  {Case{MaxLines: 2}, "a\nb\n\nc", 1},
		"blank lines ok":  {Case{MaxLines: 2}, "a\n\n\nb", 0},
		"bold":            {Case{NoMarkdown: true}, "ใช้คูปอง **JOHNAUTOCUT99**", 1},
		"heading":         {Case{NoMarkdown: true}, "## ราคา\n3,900", 1},
		"bullets":         {Case{NoMarkdown: true}, "ได้อะไรบ้าง\n- โปรแกรม\n- คอร์ส", 1},
		"numbered list":   {Case{NoMarkdown: true}, "1. สมัคร\n2. จ่าย", 1},
		"off by default":  {Case{}, "**a**\n- b\nc\nd\ne\nf\ng\nh", 0},
		"price with dash": {Case{NoMarkdown: true}, "ราคา 3,900 - จ่ายครั้งเดียว", 0},
	}
	for name, tc := range cases {
		t.Run(name, func(t *testing.T) {
			// Act
			got := checkStyle(tc.c, tc.reply)

			// Assert
			if len(got) != tc.fails {
				t.Errorf("checkStyle() = %q, want %d failures", got, tc.fails)
			}
		})
	}
}

func TestRunStyleFailureSkipsJudge(t *testing.T) {
	// Arrange
	a := &scriptedAnswerer{replies: []string{"**3,900** บาท"}}
	j := &fixedJudge{verdict: Verdict{Pass: true}}
	c := Case{Name: "bold", AccountID: 1, Expect: ExpectAnswer, Turns: []string{"ราคา"}, NoMarkdown: true}

	// Act
	rep := Run(context.Background(), Runner{Answerer: a, Handoff: keyword("แอดมิน"), Judge: j}, []Case{c})

	// Assert
	if rep.Results[0].Pass || j.calls != 0 {
		t.Fatalf("result = %+v, judge calls = %d; want a style failure without the judge", rep.Results[0], j.calls)
	}
}

func TestRunHandoffWithCriteriaJudgesTheText(t *testing.T) {
	// Arrange
	split := func(r string) (string, bool) { return strings.TrimPrefix(r, "[[H]] "), strings.HasPrefix(r, "[[H]]") }
	c := Case{Name: "vat", AccountID: 1, Expect: ExpectHandoff, Turns: []string{"ออกใบกำกับภาษีได้ไหม"},
		Criteria: []string{"says the total with VAT is 4,173"}}
	cases := map[string]struct {
		verdict Verdict
		pass    bool
	}{
		"good text": {Verdict{Pass: true}, true},
		"bad text":  {Verdict{Pass: false, Reason: "no VAT total"}, false},
	}
	for name, tc := range cases {
		t.Run(name, func(t *testing.T) {
			a := &scriptedAnswerer{replies: []string{"[[H]] ได้ครับ ยอดรวม VAT 4,173 บาท"}}
			j := &fixedJudge{verdict: tc.verdict}

			// Act
			rep := Run(context.Background(), Runner{Answerer: a, Handoff: keyword("แอดมิน"), Judge: j, Split: split}, []Case{c})

			// Assert
			if rep.Results[0].Pass != tc.pass || j.calls != 1 {
				t.Fatalf("result = %+v, judge calls = %d", rep.Results[0], j.calls)
			}
		})
	}
}

func TestRunNotHumanFailsWhenAsked(t *testing.T) {
	// Arrange
	no, yes := false, true
	cases := map[string]struct {
		human bool
		v     Verdict
		pass  bool
	}{
		"robotic, human asked":     {true, Verdict{Pass: true, Human: &no, Reason: "reads like a form letter"}, false},
		"robotic, human not asked": {false, Verdict{Pass: true, Human: &no}, true},
		"natural":                  {true, Verdict{Pass: true, Human: &yes}, true},
	}
	for name, tc := range cases {
		t.Run(name, func(t *testing.T) {
			a := &scriptedAnswerer{replies: []string{"reply"}}
			c := Case{Name: name, AccountID: 1, Expect: ExpectAnswer, Turns: []string{"ราคา"}, Human: tc.human}

			// Act
			rep := Run(context.Background(), Runner{Answerer: a, Handoff: keyword("แอดมิน"), Judge: &fixedJudge{verdict: tc.v}}, []Case{c})

			// Assert
			if rep.Results[0].Pass != tc.pass {
				t.Fatalf("result = %+v, want pass=%v", rep.Results[0], tc.pass)
			}
		})
	}
}

func TestJudgePromptShowsHistoryCriteriaAndReference(t *testing.T) {
	// Arrange
	in := JudgeInput{Reply: "r", Case: Case{Expect: ExpectAnswer, Human: true,
		History:   []Message{{Role: "user", Content: "ราคาเท่าไหร่"}, {Role: "assistant", Content: "3,900 บาทครับ"}},
		Turns:     []string{"แพงจัง"},
		Criteria:  []string{"ask one question about their work"},
		Avoid:     []string{"repeat the promo"},
		Reference: "เข้าใจครับ ปกติทำคลิปแนวไหนครับ"}}

	// Act
	p := judgePrompt(in)

	// Assert
	for _, want := range []string{"Bot: 3,900 บาทครับ", "Customer: แพงจัง", "ask one question about their work", "repeat the promo", "เข้าใจครับ ปกติทำคลิปแนวไหนครับ", "human"} {
		if !strings.Contains(p, want) {
			t.Errorf("judge prompt lacks %q:\n%s", want, p)
		}
	}
}

func TestReportWriteHumanMetric(t *testing.T) {
	// Arrange
	no, yes := false, true
	rep := Report{Results: []Result{{Case: Case{Expect: ExpectAnswer}, Human: &yes}, {Case: Case{Expect: ExpectAnswer}, Human: &no}}}
	var b strings.Builder

	// Act
	rep.Write(&b)

	// Assert
	if !strings.Contains(b.String(), "human-like 1/2") {
		t.Fatalf("report lacks the human-like total:\n%s", b.String())
	}
}

func TestRunHandoffOKAcceptsEitherWay(t *testing.T) {
	// Arrange
	split := func(r string) (string, bool) { return strings.TrimPrefix(r, "[[H]] "), strings.HasPrefix(r, "[[H]]") }
	c := Case{Name: "voice", AccountID: 1, Expect: ExpectAnswer, HandoffOK: true, Turns: []string{"[ข้อความเสียง]"}}
	for name, reply := range map[string]string{"asks to type": "รบกวนพิมพ์ได้ไหมครับ", "hands off": "[[H]] เดี๋ยวให้แอดมินฟังให้ครับ"} {
		t.Run(name, func(t *testing.T) {
			j := &fixedJudge{verdict: Verdict{Pass: true}}

			// Act
			rep := Run(context.Background(), Runner{Answerer: &scriptedAnswerer{replies: []string{reply}}, Handoff: keyword("แอดมิน"), Judge: j, Split: split}, []Case{c})

			// Assert
			if !rep.Results[0].Pass || j.calls != 1 {
				t.Fatalf("result = %+v, judge calls = %d; want a pass graded by the judge", rep.Results[0], j.calls)
			}
		})
	}
}

func TestRunSetsTheCaseClock(t *testing.T) {
	// Arrange
	var got []time.Time
	cases := []Case{
		{Name: "after promo", AccountID: 1, Expect: ExpectAnswer, Turns: []string{"ยังได้ 3,900 ไหม"}, Now: "2026-12-02T10:00:00+07:00"},
		{Name: "today", AccountID: 1, Expect: ExpectAnswer, Turns: []string{"ราคา"}},
	}
	r := Runner{Answerer: &scriptedAnswerer{replies: []string{"a", "b"}}, Handoff: keyword("แอดมิน"),
		Judge: &fixedJudge{verdict: Verdict{Pass: true}}, SetNow: func(t time.Time) { got = append(got, t) }}

	// Act
	Run(context.Background(), r, cases)

	// Assert
	if len(got) != 2 || got[0].Day() != 2 || got[0].Month() != time.December || !got[1].IsZero() {
		t.Fatalf("clock set to %v, want 2 Dec then zero (real time)", got)
	}
}

func TestValidateNow(t *testing.T) {
	// Act
	err := Validate([]Case{{Name: "bad clock", AccountID: 1, Expect: ExpectAnswer, Turns: []string{"x"}, Now: "2 Dec"}})

	// Assert
	if err == nil || !strings.Contains(err.Error(), "now") {
		t.Fatalf("Validate() = %v, want a now error", err)
	}
}

func TestJudgeInstructionAllowsTheHandoffLine(t *testing.T) {
	// Assert
	if !strings.Contains(judgeInstruction, "staff member will continue") {
		t.Fatal("the judge must accept the standard handoff line as correct")
	}
}

func TestReportWriteJSONKeepsFullReplies(t *testing.T) {
	// Arrange
	long := strings.Repeat("ยาว", 150)
	rep := Report{Results: []Result{{Case: Case{Name: "n1"}, Reply: long, Handoff: true, Pass: false, Reason: "why"}}}
	var b strings.Builder

	// Act
	err := rep.WriteJSON(&b)

	// Assert
	if err != nil || !strings.Contains(b.String(), long) || !strings.Contains(b.String(), `"handoff": true`) || !strings.Contains(b.String(), `"name": "n1"`) {
		t.Fatalf("WriteJSON() = %v\n%s", err, b.String())
	}
}
