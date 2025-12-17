class Captain::ReplySuggestionService < Captain::BaseEditorService
  def reply_suggestion_message
    make_api_call(
      model: GPT_MODEL,
      messages: [
        { role: 'system', content: prompt_from_file('reply') }
      ].concat(conversation_messages)
    )
  end
end
