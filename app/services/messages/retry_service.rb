class Messages::RetryService
  def initialize(message, wait: nil)
    @message = message
    @wait = wait
  end

  def perform
    return false unless mark_for_retry

    enqueue_reply
    true
  rescue StandardError
    restore_failed_state
    raise
  end

  private

  attr_reader :message, :wait

  def mark_for_retry
    message.with_lock do
      next false unless message.failed?

      @original_status = message.status
      @original_content_attributes = message.content_attributes.deep_dup
      Messages::StatusUpdateService.new(message, 'sent').perform
      message.update!(content_attributes: {})
      message.reload
      @marked_updated_at = message.updated_at
      true
    end
  end

  def enqueue_reply
    job = if wait
            SendReplyJob.set(wait: wait).perform_later(message.id)
          else
            SendReplyJob.perform_later(message.id)
          end

    return if job.successfully_enqueued?

    raise ActiveJob::EnqueueError, "Could not enqueue SendReplyJob for message #{message.id}"
  end

  def restore_failed_state
    return if @marked_updated_at.blank?

    message.with_lock do
      next unless message.sent? && message.updated_at == @marked_updated_at

      message.update!(
        status: @original_status,
        content_attributes: @original_content_attributes
      )
    end
  end
end
