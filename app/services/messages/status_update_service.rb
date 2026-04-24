class Messages::StatusUpdateService
  attr_reader :message, :status, :external_error

  def initialize(message, status, external_error = nil)
    @message = message
    @status = status
    @external_error = external_error
  end

  def perform
    return false unless valid_status_transition?

    update_message_status
  end

  private

  def update_message_status
    message.update!(
      status: status,
      external_error: resolved_external_error
    )
  end

  def resolved_external_error
    return nil unless status == 'failed'

    # Preserve existing error if no new error provided
    external_error || message.external_error
  end

  def valid_status_transition?
    return false unless Message.statuses.key?(status)

    current_status = message.status
    new_priority = Message.statuses[status]
    current_priority = Message.statuses[current_status] || -1

    # Allow: forward transitions, any transition to/from failed, or from nil
    status == 'failed' || current_status == 'failed' || new_priority >= current_priority
  end
end
