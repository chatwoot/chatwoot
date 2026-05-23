class Messages::StatusUpdateService
  STATUS_PRIORITY = {
    'sent' => 1,
    'delivered' => 2,
    'read' => 3
  }.freeze

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
    update_attributes = { status: status }
    update_attributes[:external_error] = nil unless status == 'failed'
    update_attributes[:external_error] = external_error if status == 'failed' && !external_error.nil?

    message.update!(update_attributes)
  end

  def valid_status_transition?
    return false unless Message.statuses.key?(status)
    return true if status == 'failed'

    current_priority = STATUS_PRIORITY[message.status]
    next_priority = STATUS_PRIORITY[status]
    return true if current_priority.blank? || next_priority.blank?

    next_priority >= current_priority
  end
end
