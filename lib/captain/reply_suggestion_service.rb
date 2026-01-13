class Captain::ReplySuggestionService < Captain::BaseTaskService
  pattr_initialize [:account!, :conversation_display_id!]

  def perform
    make_api_call(
      model: configured_model,
      messages: [
        { role: 'system', content: prompt_from_file('reply') }
      ].concat(conversation_messages)
    )
  end

  private

  def event_name
    'reply_suggestion'
  end

  def feature_key
    'editor'
  end
end
