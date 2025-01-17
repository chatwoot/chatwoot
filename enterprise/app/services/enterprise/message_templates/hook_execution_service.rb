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
    # we don't check the captain usage limits here intentionally
    # as the usage limits are checked in the job itself
    # this is to ensure that the handoff can be done there if it's required
    conversation.pending? && message.incoming? && inbox.captain_assistant.present?
  end
end
