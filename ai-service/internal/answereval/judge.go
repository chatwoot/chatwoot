package answereval

import (
	"context"
	"fmt"
	"strings"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/llm"
)

// Completer is the chat model the judge calls.
type Completer interface {
	Complete(ctx context.Context, messages []llm.Message) (llm.Result, error)
}

// LLMJudge grades a reply with a chat model.
type LLMJudge struct {
	LLM Completer
}

const judgeInstruction = `You grade replies from a customer support chatbot for a business.
You get the conversation, the business profile and knowledge base excerpts the bot was given, the bot's last reply, and what was expected.
Business facts are prices, dates, policies, contact details, product features and anything else specific to the business.

Fail the reply if any of these is true:
- It states a business fact that is not in the profile or the excerpts (invented or guessed).
- It contradicts the profile or the excerpts.
- Expected "answer": it does not answer the customer's last question, or misses what the expectation note asks for.
- Expected "unknown": it does not say it doesn't know or isn't sure, or it does not offer a staff member or a contact channel.
- It is not in the language the customer used in the last message.

Otherwise pass it. Tone, length and wording are not reasons to fail.
Reply with JSON only: {"pass": true|false, "reason": "<one short sentence>"}`

// Judge asks the model for a verdict.
func (j LLMJudge) Judge(ctx context.Context, in JudgeInput) (Verdict, error) {
	res, err := j.LLM.Complete(ctx, []llm.Message{
		{Role: "system", Content: judgeInstruction},
		{Role: "user", Content: judgePrompt(in)},
	})
	if err != nil {
		return Verdict{}, err
	}
	return parseVerdict(res.Content)
}

func judgePrompt(in JudgeInput) string {
	var b strings.Builder
	b.WriteString("Conversation (customer turns; the bot's earlier replies are omitted):\n")
	for _, t := range in.Case.Turns {
		b.WriteString("- Customer: " + t + "\n")
	}
	if in.Profile != "" {
		b.WriteString("\nBusiness profile:\n" + in.Profile + "\n")
	}
	b.WriteString("\nKnowledge base excerpts:\n")
	if len(in.Excerpts) == 0 {
		b.WriteString("(none: the knowledge base had nothing relevant)\n")
	}
	for i, e := range in.Excerpts {
		fmt.Fprintf(&b, "[%d] %s\n", i+1, e)
	}
	fmt.Fprintf(&b, "\nExpected: %s\n", in.Case.Expect)
	if in.Case.Note != "" {
		b.WriteString("Expectation note: " + in.Case.Note + "\n")
	}
	b.WriteString("\nBot's last reply:\n" + in.Reply + "\n")
	return b.String()
}
