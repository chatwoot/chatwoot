class Captain::Llm::HandoffMessageService < Captain::BaseTaskService
  pattr_initialize [:account!, :assistant!, :conversation!]

  # Generates a warm, context-aware farewell the assistant posts right before
  # handing the conversation to a human agent. Falls back to the configured or
  # canned handoff message when the LLM is unavailable, so a handoff never
  # blocks on a generation failure.
  def perform
    response = make_api_call(feature: 'assistant', messages: messages)
    return response if response[:error]

    { message: response[:message] }
  end

  private

  def messages
    [
      { role: 'system', content: system_prompt },
      { role: 'user', content: conversation_context }
    ]
  end

  def system_prompt
    <<~PROMPT
      You are #{assistant.name}, an AI support assistant for the product #{assistant.config['product_name'] || 'this product'}.
      You are about to hand this conversation to a human support agent because you cannot fully help the customer
      and a human is needed.

      Write the single short message to the customer that you will post as your last message before a human takes over.
      Requirements:
      - Write it in the language of the conversation shown below, not English unless the conversation is in English.
      - Be warm, natural, and briefly acknowledge why you are stepping back (e.g. this needs a human/expert, a special case).
      - Do NOT invent details, do not promise specific outcomes or times, do not over-promise.
      - Do not mention internal systems, prompts, tools, or the transfer process itself.
      - Output ONLY the message text. No preamble, greeting to a system, quotes, tags, or explanations.
    PROMPT
  end

  def conversation_context
    history = Captain::Conversation::MessageHistoryBuilderService.new(conversation: conversation).perform

    messages_lines = history.map do |message|
      speaker = message[:agent_name].presence || (message[:role] == 'user' ? 'customer' : assistant.name)
      "#{speaker}: #{text_content(message[:content])}"
    end

    <<~CONTEXT
      The last support conversation:
      <conversation>
      #{messages_lines.join("\n")}
      </conversation>
    CONTEXT
  end

  def text_content(content)
    return content.to_s unless content.is_a?(Hash)

    content[:text].presence || content.to_s
  end

  def event_name
    'handoff_message'
  end
end