module Enterprise::MessageTemplates::HookExecutionService
  MAX_ATTACHMENT_WAIT_SECONDS = 4

  def trigger_templates
    super
    return unless should_process_captain_response?
    return perform_handoff unless inbox.captain_active?

    track_captain_engagement
    schedule_captain_response
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

  def track_captain_engagement
    return unless captain_v2_enabled?

    Captain::ConversationEvents.engaged(
      conversation: conversation,
      assistant: inbox.captain_assistant,
      at: message.created_at
    )
  end

  def captain_v2_enabled?
    conversation.account.feature_enabled?('captain_integration_v2')
  end

  def schedule_captain_response
    job_args = [conversation, conversation.inbox.captain_assistant]
    captain_v2_enabled = conversation.account.feature_enabled?('captain_integration_v2')
    job_args << message.id if captain_v2_enabled
    wait_time = attachment_wait_time(captain_v2_enabled)

    if wait_time.zero?
      Captain::Conversation::ResponseBuilderJob.perform_later(*job_args)
    else
      Captain::Conversation::ResponseBuilderJob.set(wait: wait_time).perform_later(*job_args)
    end
  end

  def attachment_wait_time(captain_v2_enabled)
    attachment_count = captain_v2_enabled ? recent_attachment_count : message.attachments.size
    return 0.seconds if attachment_count.zero?

    calculate_attachment_wait_time(attachment_count)
  end

  def recent_attachment_count
    maximum_wait = (MAX_ATTACHMENT_WAIT_SECONDS + 1).seconds

    conversation.messages.incoming
                .joins(:attachments)
                .where(attachments: { created_at: maximum_wait.ago.. })
                .count
  end

  def calculate_attachment_wait_time(attachment_count)
    base_wait = 1.second

    # Wait longer for more attachments or larger files
    additional_wait = [attachment_count * 1, MAX_ATTACHMENT_WAIT_SECONDS].min.seconds
    base_wait + additional_wait
  end

  def should_process_captain_response?
    conversation.pending? && message.captain_response_triggering? && inbox.captain_assistant.present?
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
    conversation.pending? && inbox.respond_to?(:captain_assistant) && inbox.captain_assistant.present?
  end
end
