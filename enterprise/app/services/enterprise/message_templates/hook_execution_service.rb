module Enterprise::MessageTemplates::HookExecutionService
  def trigger_templates
    super
    return unless should_process_captain_response?
    return perform_handoff unless inbox.captain_active?

    Captain::Conversation::ResponseSchedulerService.new(message: message).perform
  end

  def should_send_greeting?
    return false if captain_handling_conversation?

    super
  end

  def should_send_out_of_office_message?
    return false if captain_handling_conversation?

    super
  end

  def should_send_email_collect?
    return false if captain_handling_conversation?

    super
  end

  private

  def captain_v2_enabled?
    conversation.account.feature_enabled?('captain_integration_v2')
  end

  def should_process_captain_response?
    # Audience and schedule are decided when Captain first takes or reopens a conversation.
    # Do not re-evaluate an existing pending conversation for each new message.
    conversation.pending? && message.captain_response_triggering? && captain_assistant_configured? && !inbox.external_bot_active?
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
    if captain_v2_enabled?
      Captain::ConversationEvents.handed_off(
        conversation: conversation,
        assistant: inbox.captain_assistant,
        source: Captain::ConversationEvents::Sources::USAGE_LIMIT,
        reason_category: :usage_limit,
        at: Time.current
      )
    end
    send_out_of_office_message_after_handoff
  end

  def send_out_of_office_message_after_handoff
    # Campaign conversations should never receive OOO templates — the campaign itself
    # serves as the initial outreach, and OOO would be confusing in that context.
    return if conversation.campaign.present?

    ::MessageTemplates::Template::OutOfOffice.perform_if_applicable(conversation)
  end

  def captain_handling_conversation?
    conversation.pending? && captain_assistant_configured?
  end

  def captain_assistant_configured?
    inbox.captain_assistant.present?
  end
end
