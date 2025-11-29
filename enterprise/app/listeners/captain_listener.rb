class CaptainListener < BaseListener
  include ::Events::Types

  def message_created(event)
    message = extract_message_and_account(event)[0]
    return unless should_analyze_priority?(message)

    # Debounce: only analyze if this is a new incoming message
    # and we haven't analyzed recently (within last 5 minutes)
    conversation = message.conversation
    return if recently_analyzed?(conversation)

    Captain::Conversation::PriorityUpdateJob.perform_later(conversation)
  end

  def conversation_resolved(event)
    conversation = extract_conversation_and_account(event)[0]
    assistant = conversation.inbox.captain_assistant

    return unless conversation.inbox.captain_active?

    Captain::Llm::ContactNotesService.new(assistant, conversation).generate_and_update_notes if assistant.config['feature_memory'].present?
    Captain::Llm::ConversationFaqService.new(assistant, conversation).generate_and_deduplicate if assistant.config['feature_faq'].present?
  end

  private

  def should_analyze_priority?(message)
    # Only analyze incoming messages from customers
    return false unless message.incoming?
    return false if message.private?

    # Check if smart priority is enabled for this account
    account = message.account
    account.feature_enabled?('smart_priority')
  end

  def recently_analyzed?(conversation)
    # Check if priority_factors has been updated in the last 5 minutes
    return false if conversation.priority_factors.blank?

    # If the conversation was updated recently, skip re-analysis
    conversation.updated_at > 5.minutes.ago && conversation.priority_score.positive?
  end
end
