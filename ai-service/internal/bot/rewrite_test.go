package bot

import (
	"context"
	"errors"
	"io"
	"log/slog"
	"strings"
	"testing"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/llm"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/memory"
)

func TestParseRewrite(t *testing.T) {
	cases := map[string]struct {
		in   string
		want []string
	}{
		"two labelled lines":     {"TH: ราคาคอร์ส AutoCut\nEN: AutoCut course price", []string{"ราคาคอร์ส AutoCut", "AutoCut course price"}},
		"blank lines and spaces": {"\n  th:  โปรหมดเขตเมื่อไหร่ \n\n en: promotion end date\n", []string{"โปรหมดเขตเมื่อไหร่", "promotion end date"}},
		"unlabelled lines kept":  {"ราคา\nprice", []string{"ราคา", "price"}},
		"extra lines dropped":    {"a\nb\nc", []string{"a", "b"}},
		"empty":                  {"  \n", nil},
	}
	for name, c := range cases {
		t.Run(name, func(t *testing.T) {
			// Act
			got := parseRewrite(c.in)

			// Assert
			if strings.Join(got, "|") != strings.Join(c.want, "|") {
				t.Errorf("parseRewrite(%q) = %q, want %q", c.in, got, c.want)
			}
		})
	}
}

func TestParseRewriteCapsLength(t *testing.T) {
	// Arrange
	long := "TH: " + strings.Repeat("ก", maxQueryRunes+50)

	// Act
	got := parseRewrite(long)

	// Assert
	if len(got) != 1 || len([]rune(got[0])) != maxQueryRunes {
		t.Fatalf("got %d queries, first %d runes; want 1 query of %d runes", len(got), len([]rune(got[0])), maxQueryRunes)
	}
}

func TestLLMRewriterSendsRecentTurns(t *testing.T) {
	// Arrange
	l := &fakeLLM{reply: "TH: ราคาคอร์ส\nEN: course price"}
	rw := &LLMRewriter{LLM: l}
	history := []memory.Turn{
		{Role: "user", Content: "AutoCut คืออะไร"},
		{Role: "assistant", Content: "ระบบตัดต่อ"},
		{Role: "user", Content: "How much is it?"},
	}

	// Act
	got, err := rw.Rewrite(context.Background(), history)

	// Assert
	if err != nil || strings.Join(got, "|") != "ราคาคอร์ส|course price" {
		t.Fatalf("Rewrite() = %q, %v", got, err)
	}
	last := l.got[len(l.got)-1].Content
	for _, want := range []string{"AutoCut คืออะไร", "How much is it?"} {
		if !strings.Contains(last, want) {
			t.Errorf("rewrite request is missing %q:\n%s", want, last)
		}
	}
}

type recordingRetriever struct{ queries []string }

func (r *recordingRetriever) Retrieve(_ context.Context, _, _ int64, q ...string) ([]knowledge.Hit, error) {
	r.queries = q
	return []knowledge.Hit{{DocumentID: 1, ChunkID: 1, Content: "ราคา 3,900 บาท", Score: 0.8}}, nil
}

type fakeRewriter struct {
	out []string
	err error
}

func (f fakeRewriter) Rewrite(context.Context, []memory.Turn) ([]string, error) { return f.out, f.err }

func answerBot(l *fakeLLM, kb Retriever, rw QueryRewriter) *Bot {
	return New(Options{
		LLM: l, Knowledge: kb, Rewriter: rw, SystemPrompt: "SYS",
		History: memory.NewHistory(20, 0, nil),
		Logger:  slog.New(slog.NewJSONHandler(io.Discard, nil)),
	}, 1, 1)
}

func TestAnswerSearchesWithRewrittenQueries(t *testing.T) {
	// Arrange
	l, kb := &fakeLLM{reply: "3,900 บาท"}, &recordingRetriever{}
	b := answerBot(l, kb, fakeRewriter{out: []string{"ราคาคอร์ส", "course price"}})
	history := []memory.Turn{{Role: "user", Content: "How much is it?"}}

	// Act
	res, hits, err := b.Answer(context.Background(), 1, 0, history)

	// Assert
	if err != nil || res.Content != "3,900 บาท" || len(hits) != 1 {
		t.Fatalf("Answer() = %+v, %d hits, %v", res, len(hits), err)
	}
	if strings.Join(kb.queries, "|") != "How much is it?|ราคาคอร์ส|course price" {
		t.Errorf("queries = %q, want original then rewritten", kb.queries)
	}
	if !strings.Contains(l.got[1].Content, "3,900") {
		t.Errorf("knowledge excerpt missing from prompt: %+v", l.got)
	}
}

func TestAnswerKeepsOriginalQueriesWhenRewriteFails(t *testing.T) {
	// Arrange
	l, kb := &fakeLLM{reply: "ok"}, &recordingRetriever{}
	b := answerBot(l, kb, fakeRewriter{err: errors.New("timeout")})

	// Act
	_, _, err := b.Answer(context.Background(), 1, 0, []memory.Turn{{Role: "user", Content: "ราคาเท่าไหร่"}})

	// Assert
	if err != nil || strings.Join(kb.queries, "|") != "ราคาเท่าไหร่" {
		t.Fatalf("queries = %q, err = %v; want the original query only", kb.queries, err)
	}
}

func TestAnswerReturnsLLMError(t *testing.T) {
	// Arrange
	b := answerBot(&fakeLLM{err: errors.New("down")}, nil, nil)

	// Act
	_, _, err := b.Answer(context.Background(), 1, 0, []memory.Turn{{Role: "user", Content: "hi"}})

	// Assert
	if err == nil {
		t.Fatal("Answer() error = nil, want the LLM error")
	}
}

var _ = llm.Message{}
