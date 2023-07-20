module Enterprise::MessageTemplates::HookExecutionService
  def trigger_templates
    super
    ResponseBotJob.perform_later(conversation) if should_process_response_bot?
  end

  def should_process_response_bot?
    return false unless conversation.pending?
    return false unless message.incoming?
    return false unless inbox.response_bot_enabled?

    true
  end
end
