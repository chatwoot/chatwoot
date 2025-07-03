module Enterprise::MessageTemplates::HookExecutionService
  def trigger_templates
    super
    return unless should_process_captain_response?
    return perform_handoff unless inbox.captain_active?

    Captain::Conversation::ResponseBuilderJob.perform_later(
      conversation,
      conversation.inbox.captain_assistant
    )
  end

  def should_process_captain_response?
    conversation.pending? && message.incoming? && inbox.captain_assistant.present?
  end

  def perform_handoff
    return unless conversation.pending?

    Rails.logger.info("Captain limit exceeded, performing handoff mid-conversation for conversation: #{conversation.id}")
    conversation.messages.create!(
      message_type: :outgoing,
      account_id: conversation.account.id,
      inbox_id: conversation.inbox.id,
      content: 'Transferring to another agent for further assistance.'
    )
    conversation.bot_handoff!
  end
end
