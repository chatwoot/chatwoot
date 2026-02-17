class Captain::SummaryService < Captain::BaseTaskService
  pattr_initialize [:account!, :conversation_display_id!, { force_regenerate: false }]

  def perform
    return cached_response if use_cache?

    generate_and_cache_summary
  end

  private

  def event_name
    'summarize'
  end

  def use_cache?
    return false if force_regenerate
    return false if conversation.cached_summary.blank?
    return false if conversation.cached_summary_at.blank?

    conversation.cached_summary_at >= conversation.last_activity_at
  end

  def cached_response
    { message: conversation.cached_summary }
  end

  def generate_and_cache_summary
    msg_count = conversation_message_count
    result = make_api_call(
      model: summary_model(msg_count),
      messages: [
        { role: 'system', content: prompt_from_file('summary') },
        { role: 'user', content: build_summary_content(msg_count) }
      ]
    )

    cache_summary(result[:message]) if result[:message].present? && result[:error].blank?

    result
  end

  def conversation_message_count
    conversation.messages.where(message_type: [:incoming, :outgoing]).count
  end

  def summary_model(msg_count)
    msg_count < 7 ? GPT_MODEL : 'gpt-4.1'
  end

  def build_summary_content(msg_count)
    llm_text = conversation.to_llm_text(include_contact_details: false)
    context = build_conversation_context(msg_count)
    context.present? ? "#{llm_text}\n\n#{context}" : llm_text
  end

  def build_conversation_context(msg_count)
    ['Conversation Stats:', *context_fields(msg_count).compact].join("\n")
  end

  def context_fields(msg_count)
    [
      "Message count: #{msg_count}",
      ("Status: #{conversation.status}" if conversation.status.present?),
      ("Priority: #{conversation.priority}" if conversation.priority.present?),
      ("Labels: #{conversation.cached_label_list}" if conversation.cached_label_list.present?),
      *account_context_fields
    ]
  end

  def account_context_fields
    [
      ("Account industry: #{account.custom_attributes['industry']}" if account.custom_attributes&.dig('industry').present?),
      ("Summary language: #{account.locale}" if account.locale.present?)
    ]
  end

  def cache_summary(summary)
    conversation.update(
      cached_summary: summary,
      cached_summary_at: Time.current
    )
  end
end
