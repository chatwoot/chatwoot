class Captain::Llm::ConversationFaqPromptsService
  class << self
    def generator(language = 'english')
      <<~PROMPT
        You create high-quality FAQ candidates from resolved support conversations.
        Only generate an FAQ when the conversation contains durable, reusable knowledge that would help many future customers.

        ## Source rules
        - The input starts with trusted business context. Use it to reject conversations about other businesses or topics, but never use it as the source of an FAQ answer.
        - The conversation history contains only customer messages and human support agent messages.
        - Base every FAQ strictly on information stated in the human support agent messages. Do not infer, generalize, or add external knowledge.
        - A human support agent must state every fact used in the FAQ answer. Customer messages cannot supply missing answer facts.
        - The human support agent must provide the final answer. If the agent only greets, asks clarifying questions, asks for contact details, promises to check, shares an attachment, or transfers the conversation, return: `{"faqs":[]}`.
        - For each FAQ, identify the human support agent message or messages that together provide a complete public answer to the same question. Combine facts only across related agent messages; never combine separate questions or unrelated topics. If those messages do not provide a complete public answer, remove that FAQ.

        ## Decision gate
        Return `{"faqs":[]}` unless every generated FAQ can pass all of these checks:
        1. The answer is fully stated by a human support agent, not by the customer.
        2. The answer is a public, durable rule or procedure, not a private account action, manual review, troubleshooting session, quote, file, link, or follow-up.
        3. The answer can be written without private identifiers, customer-specific facts, direct URLs, attachments, invoices, screenshots, or support-ticket steps.
        4. The question would still make sense in a help center if the original conversation, customer, and agent did not exist.
        Do not rescue a rejected conversation by rewriting it as a generic support question.

        ## Return no FAQ for
        - Spam, scams, advertisements, SEO/link-building pitches, adult/gambling/financial promotions, gibberish, abusive content, or conversations unrelated to the business being supported.
        - Account-specific, order-specific, payment-specific, subscription-specific, login/access, verification, delivery, certificate, or troubleshooting issues, even if they could be rewritten as a general support question.
        - Conversations that mainly hand off to a human, ask the customer to wait, request private identifiers or contact details, collect screenshots, attachments, or documents, or tell the customer to contact support for case review.
        - Temporary workarounds, one-off exceptions, unclear answers, unresolved problems, wrong-service conversations, complaints, greetings, or abandoned conversations.
        - Internal support workflow details, chat session rules, escalation mechanics, ticket-routing instructions, or "someone will get back to you" messages.
        - Answers that are just a direct/private link, attachment, file, invoice, one-off quote or estimate, account-specific URL, or instructions to open a support ticket.
        - Questions whose useful answer is "contact support", "wait for the team", "share your details", "we will check", or "this needs manual review".
        - Questions about whether support can help with a private issue, third-party service, transaction, payment, delivery, or account problem.
        - Pricing, policy, availability, roadmap, deadline, or legal claims unless the human support agent gives a clear and stable answer in the conversation.
        - Questions already answered only by asking the customer for more information.

        ## FAQ quality rules
        - Prefer returning no FAQ over a weak or narrow FAQ.
        - A good candidate teaches a generally reusable product, service, policy, setup, or process rule that another customer could use without contacting support.
        - Generate at most one FAQ unless the human agent clearly answered multiple distinct, reusable questions.
        - Do not create duplicate or overlapping FAQs in the same response.
        - Questions must be general enough for a help center, not personalized to the current customer.
        - Remove customer names, order numbers, invoice numbers, IDs, private URLs, phone numbers, emails, screenshots, attachments, and other personal or transaction-specific details.
        - Answers must be complete, self-contained, and supported by the human agent's messages.

        ## Examples
        - Customer mentions a price or procedure, then the human agent only greets or says they will check: return `{"faqs":[]}`.
        - Human agent shares only a private link, file, invoice, quote, screenshot, or attachment: return `{"faqs":[]}`.
        - Human agent clearly states a public rule, such as which purchases are allowed for a program or service: generate one general FAQ.

        Generate the FAQs only in the #{language}, use no other language.
        If no suitable reusable FAQ is available, return: `{"faqs":[]}`.

        Return only valid JSON in this exact structure:
        ```json
        { "faqs": [ { "question": "", "answer": "" } ] }
        ```
      PROMPT
    end

    def same_faq
      <<~PROMPT
        Decide whether the new FAQ and existing FAQ are the same.

        Return `same_faq` as true only when both questions ask the same thing and both answers give the same guidance.
        Wording, grammar, level of detail, and examples may differ. Return false when either FAQ adds, removes, contradicts, or changes a condition,
        policy, procedure, audience, product, plan, time frame, or outcome. Related FAQs are not the same FAQ. When uncertain, return false.

        Return only valid JSON in this exact structure:
        ```json
        { "same_faq": true }
        ```
      PROMPT
    end
  end
end
