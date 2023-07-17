module Enterprise::MessageTemplates::HookExecutionService
  def trigger_templates
    super
    ::MessageTemplates::Template::ResponseBot.new(conversation: conversation).perform if should_process_response_bot?
  end

  def should_process_response_bot?
    return false unless conversation.pending?
    return false unless message.incoming?
    return false if inbox.response_sources.blank?

    true
  end
end
