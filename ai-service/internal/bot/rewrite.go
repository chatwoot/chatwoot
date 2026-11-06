package bot

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/llm"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/memory"
)

// maxQueryRunes caps one rewritten search query.
const maxQueryRunes = 300

// rewriteTurns is how many recent turns the rewriter sees.
const rewriteTurns = 6

// QueryRewriter turns the conversation into extra knowledge base queries.
type QueryRewriter interface {
	Rewrite(ctx context.Context, history []memory.Turn) ([]string, error)
}

// LLMRewriter asks the chat model for a stand-alone search query in Thai and
// in English. The knowledge base may be written in either language, and the
// customer may ask in either (or refer back with "how much is it?"); vector
// search across languages scores too low to pass the threshold.
type LLMRewriter struct {
	LLM     Completer
	Timeout time.Duration // 0 = 10s
}

const rewriteInstruction = "You write search queries for a customer support knowledge base. " +
	"Read the conversation and rewrite the customer's LAST message as one stand-alone search query " +
	"that names the product or topic it refers to. If the message asks several things, cover every one " +
	"of them in the query. Reply with exactly two lines and nothing else:\n" +
	"TH: <the query in Thai>\nEN: <the query in English>"

// Rewrite returns up to two queries. On error the caller keeps its own queries.
func (r *LLMRewriter) Rewrite(ctx context.Context, history []memory.Turn) ([]string, error) {
	if len(history) == 0 {
		return nil, nil
	}
	timeout := r.Timeout
	if timeout == 0 {
		timeout = 10 * time.Second
	}
	ctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	res, err := r.LLM.Complete(ctx, []llm.Message{
		{Role: "system", Content: rewriteInstruction},
		{Role: "user", Content: transcript(history)},
	})
	if err != nil {
		return nil, err
	}
	queries := parseRewrite(res.Content)
	if len(queries) == 0 {
		return nil, errors.New("rewrite returned no query")
	}
	return queries, nil
}

// transcript renders the last turns as plain text for the rewriter.
func transcript(history []memory.Turn) string {
	if len(history) > rewriteTurns {
		history = history[len(history)-rewriteTurns:]
	}
	var b strings.Builder
	for _, t := range history {
		who := "Customer"
		if t.Role == "assistant" {
			who = "Assistant"
		}
		b.WriteString(who + ": " + t.Content + "\n")
	}
	return b.String()
}

// parseRewrite reads up to two non-empty lines, dropping a "TH:"/"EN:" label.
func parseRewrite(content string) []string {
	var out []string
	for _, line := range strings.Split(content, "\n") {
		line = strings.TrimSpace(line)
		for _, label := range []string{"TH:", "EN:", "th:", "en:"} {
			line = strings.TrimSpace(strings.TrimPrefix(line, label))
		}
		if line == "" {
			continue
		}
		if r := []rune(line); len(r) > maxQueryRunes {
			line = string(r[:maxQueryRunes])
		}
		out = append(out, line)
		if len(out) == 2 {
			break
		}
	}
	return out
}
