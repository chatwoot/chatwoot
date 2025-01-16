module Enterprise::MessageTemplates::HookExecutionService
  def trigger_templates
    super
    return unless should_process_captain_response?

    Captain::Conversation::ResponseBuilderJob.perform_later(
      conversation,
      conversation.inbox.captain_assistant
    )
  end

  def should_process_captain_response?
    conversation.pending? && message.incoming? && inbox.captain_assistant.present?
  end
end
