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
- A listed criterion is not met. Judge criteria by meaning, not exact words.
- It does something listed under "must not".
- Expected "handoff": the text promises something staff have not confirmed, or misses a listed criterion.

Otherwise pass it. Tone, length and wording are not reasons to fail unless a criterion or a "must not" item is about them.
A reference reply, when given, shows the tone and approach the business wants; the bot's reply does not need its wording or every detail.

Also score two metrics:
- "faithful": true if every business fact in the reply is stated in the profile or the excerpts; false if any is not.
- "context_recall": only when expected "answer": true if the profile and excerpts together contain the facts a correct reply needs (use the expectation note); false if something needed is missing. Use null for other expectations.
- "human": only when the prompt asks for it, else null. True if the reply reads like a real person on the business's team chatting: short, warm, natural spoken language in the customer's register, at most one question, no stock assistant phrases ("as an AI", "is there anything else I can help with", "I hope this helps"), no form-letter structure. False if it reads like a bot or a brochure.

Reply with JSON only: {"pass": true|false, "reason": "<one short sentence>", "faithful": true|false, "context_recall": true|false|null, "human": true|false|null}`

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
	if len(in.Case.History) > 0 {
		b.WriteString("Conversation (the bot's earlier replies are shown where known):\n")
	} else {
		b.WriteString("Conversation (customer turns; the bot's earlier replies are omitted):\n")
	}
	for _, m := range in.Case.History {
		who := "Customer"
		if m.Role == "assistant" {
			who = "Bot"
		}
		b.WriteString("- " + who + ": " + m.Content + "\n")
	}
	for _, t := range in.Case.Turns {
		b.WriteString("- Customer: " + t + "\n")
	}
	if in.LastInput != "" {
		b.WriteString("\nThe customer's last message came with files. As the bot read it (typed text, voice transcript, file notes):\n" + in.LastInput + "\n")
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
	writeList(&b, "Criteria (each must be met)", in.Case.Criteria)
	writeList(&b, "The reply must not", in.Case.Avoid)
	if in.Case.Reference != "" {
		b.WriteString("Reference reply (tone and approach, not exact wording):\n" + in.Case.Reference + "\n")
	}
	if in.Case.Human {
		b.WriteString("Score \"human\" for this reply.\n")
	}
	b.WriteString("\nBot's last reply:\n" + in.Reply + "\n")
	return b.String()
}

func writeList(b *strings.Builder, title string, items []string) {
	if len(items) == 0 {
		return
	}
	b.WriteString(title + ":\n")
	for _, it := range items {
		b.WriteString("- " + it + "\n")
	}
}
