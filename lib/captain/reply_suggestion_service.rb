class Captain::ReplySuggestionService < Captain::BaseTaskService
  pattr_initialize [:account!, :conversation_display_id!]

  def execute_task
    make_api_call(
      model: GPT_MODEL,
      messages: [
        { role: 'system', content: prompt_from_file('reply') }
      ].concat(conversation_messages)
    )
  end

  private

  def event_name
    'reply_suggestion'
  end
end
