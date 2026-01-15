class Captain::ReplySuggestionService < Captain::BaseTaskService
  pattr_initialize [:account!, :conversation_display_id!]

  def perform
    make_api_call(
      model: GPT_MODEL,
      messages: [
        { role: 'system', content: prompt_from_file('reply') },
        { role: 'user', content: formatted_conversation }
      ]
    )
  end

  private

  def formatted_conversation
    LlmFormatter::ConversationLlmFormatter.new(conversation).format(token_limit: TOKEN_LIMIT)
  end

  def event_name
    'reply_suggestion'
  end
end
