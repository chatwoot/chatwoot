class CaptainListener < BaseListener
  include ::Events::Types

  def message_created(event)
    message = event.data[:message]
    return unless message.outgoing? && !message.private?

    if message.sender_type == 'Captain::Assistant'
      Captain::ConversationOutcomeTracker.new(conversation: message.conversation, assistant: message.sender)
                                         .record_captain_reply(message: message)
    else
      outcome_trackers(message.conversation).each { |tracker| tracker.record_human_reply(message: message) }
    end
  end

  def message_updated(event)
    message = event.data[:message]
    return unless message.input_csat?

    response = CsatSurveyResponse.find_by(message: message)
    return unless response

    outcome_trackers(message.conversation).each { |tracker| tracker.record_csat(response: response) }
  end

  def conversation_resolved(event)
    conversation = extract_conversation_and_account(event)[0]
    outcome_trackers(conversation).each { |tracker| tracker.record_resolution(at: event.timestamp) }

    assistant = conversation.inbox.captain_assistant

    return unless conversation.inbox.captain_active?

    Captain::Llm::ContactNotesService.new(assistant, conversation).generate_and_update_notes if assistant.config['feature_memory'].present?
    Captain::Llm::ConversationFaqJob.perform_later(conversation, assistant) if assistant.config['feature_faq'].present?
  end

  def conversation_opened(event)
    conversation = extract_conversation_and_account(event)[0]
    outcome_trackers(conversation).each { |tracker| tracker.record_reopen(at: event.timestamp) }
  end

  private

  def outcome_trackers(conversation)
    ConversationOutcome.where(
      account_id: conversation.account_id,
      conversation_id: conversation.id
    ).includes(:assistant).map do |outcome|
      Captain::ConversationOutcomeTracker.new(conversation: conversation, assistant: outcome.assistant)
    end
  end
end
