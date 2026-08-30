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
    # Update status and set external_error only when failed
    message.update!(
      status: status,
      external_error: (status == 'failed' ? external_error : nil)
    )
  end

  def valid_status_transition?
    return false unless Message.statuses.key?(status)

    # `deferred` exists as foundation only; the transition into it is enabled by CW-7882.
    return false if status.to_s == 'deferred'

    # Don't allow changing from 'read' to 'delivered'
    return false if message.read? && status == 'delivered'

    true
  end
end
