module Captain::Conversation::ResponseLifecycleLogging
  private

  def initialize_response_lifecycle(conversation, assistant, responding_to_message_id)
    @conversation = conversation
    @inbox = conversation.inbox
    @assistant = assistant
    @responding_to_message_id = responding_to_message_id if captain_v2_enabled?
    log_lifecycle(:job_started, conversation_status: @conversation.status)
  end

  def log_skip(reason)
    log_lifecycle(:job_skipped, reason: reason, conversation_status: @observed_conversation_status)
  end

  def log_discard(reason)
    log_lifecycle(
      :response_discarded,
      reason: reason,
      responding_to_message_id: @responding_to_message_id
    )
  end

  def log_lifecycle(event, level: :info, **attributes)
    Captain::Conversation::ResponseLifecycleLogger.public_send(
      level,
      event,
      account_id: @conversation.account_id,
      conversation_id: @conversation.id,
      conversation_display_id: @conversation.display_id,
      inbox_id: @conversation.inbox_id,
      assistant_id: @assistant.id,
      responding_to_message_id: @responding_to_message_id,
      active_job_id: job_id,
      provider_job_id: provider_job_id,
      **attributes
    )
  end
end
