module Enterprise::MessageTemplates::HookExecutionService
  def trigger_templates
    super
    ResponseBot::ResponseBotJob.perform_later(conversation) if should_process_response_bot?
  end

  def should_process_response_bot?
    conversation.pending? && message.incoming? && inbox.response_bot_enabled?
  end
end
