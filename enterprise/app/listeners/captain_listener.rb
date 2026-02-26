class CaptainListener < BaseListener
  include ::Events::Types

  def conversation_resolved(event)
    conversation = extract_conversation_and_account(event)[0]
    assistant = conversation.inbox.captain_assistant

    return unless conversation.inbox.captain_active?

    create_captain_reporting_event(conversation, 'captain_conversation_resolved', captain_source(event)) if performed_by_captain?(event)
    Captain::Llm::ContactNotesService.new(assistant, conversation).generate_and_update_notes if assistant.config['feature_memory'].present?
    Captain::Llm::ConversationFaqService.new(assistant, conversation).generate_and_deduplicate if assistant.config['feature_faq'].present?
  end

  def conversation_bot_handoff(event)
    conversation = extract_conversation_and_account(event)[0]

    return unless performed_by_captain?(event)

    create_captain_reporting_event(conversation, 'captain_conversation_handoff', captain_source(event))
  end

  private

  def performed_by_captain?(event)
    event.data[:performed_by].is_a?(Captain::Assistant)
  end

  def captain_source(event)
    event.data[:captain_action_source].presence || 'assistant'
  end

  def create_captain_reporting_event(conversation, event_name, source)
    ReportingEvent.create!(
      name: event_name,
      source: source,
      value: conversation.updated_at.to_i - conversation.created_at.to_i,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      user_id: conversation.assignee_id,
      conversation_id: conversation.id,
      event_start_time: conversation.created_at,
      event_end_time: conversation.updated_at
    )
  end
end
