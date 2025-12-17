class Captain::ReplySuggestionService < Captain::BaseEditorService
  def reply_suggestion_message
    make_api_call(reply_suggestion_body)
  end

  private

  def reply_suggestion_body
    {
      model: GPT_MODEL,
      messages: [
        { role: 'system', content: prompt_from_file('reply') }
      ].concat(conversation_messages)
    }
  end
end
