class Captain::Conversation::ResponseSchedulerService
  MAX_ATTACHMENT_WAIT_SECONDS = 4

  def initialize(message:)
    @message = message
    @conversation = message.conversation
    @assistant = message.inbox.captain_assistant
  end

  def perform
    track_captain_engagement
    enqueue_response(attachment_wait_time)
  end

  private

  def enqueue_response(wait_time)
    return Captain::Conversation::ResponseBuilderJob.perform_later(*job_args) if wait_time.zero?

    Captain::Conversation::ResponseBuilderJob.set(wait: wait_time).perform_later(*job_args)
  rescue StandardError => e
    log_lifecycle(:enqueue_failed, level: :error, wait_seconds: wait_time&.to_f, error_class: e.class.name)
    raise
  end

  def log_lifecycle(event, level: :info, **attributes)
    Captain::Conversation::ResponseLifecycleLogger.public_send(
      level,
      event,
      account_id: @conversation.account_id,
      conversation_id: @conversation.id,
      conversation_display_id: @conversation.display_id,
      inbox_id: @conversation.inbox_id,
      assistant_id: @assistant&.id,
      message_id: @message.id,
      conversation_status: @conversation.status,
      **attributes
    )
  end

  def job_args
    args = [@conversation, @assistant]
    args << @message.id if captain_v2_enabled?
    args
  end

  def track_captain_engagement
    return unless captain_v2_enabled?

    Captain::ConversationEvents.engaged(
      conversation: @conversation,
      assistant: @assistant,
      at: @message.created_at
    )
  end

  def captain_v2_enabled?
    @conversation.account.feature_enabled?('captain_integration_v2')
  end

  def attachment_wait_time
    attachment_count = captain_v2_enabled? ? recent_attachment_count : @message.attachments.size
    return 0.seconds if attachment_count.zero?

    base_wait = 1.second
    additional_wait = [attachment_count, MAX_ATTACHMENT_WAIT_SECONDS].min.seconds
    base_wait + additional_wait
  end

  def recent_attachment_count
    maximum_wait = (MAX_ATTACHMENT_WAIT_SECONDS + 1).seconds

    @conversation.messages.incoming
                 .joins(:attachments)
                 .where(attachments: { created_at: maximum_wait.ago.. })
                 .count
  end
end
