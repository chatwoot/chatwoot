class Plivo::DeliveryStatusService
  pattr_initialize [:inbox!, :params!]

  # Plivo message states:
  # https://www.plivo.com/docs/sms/api/message#the-message-object
  STATUS_MAPPING = {
    'sent' => 'sent',
    'delivered' => 'delivered',
    'undelivered' => 'failed',
    'failed' => 'failed',
    'rejected' => 'failed'
  }.freeze

  def perform
    return unless supported_status?

    process_status if message.present?
  end

  private

  def process_status
    @message.status = status
    @message.external_error = external_error if error_occurred?
    @message.save!
  end

  def supported_status?
    STATUS_MAPPING.key?(params[:status])
  end

  def status
    STATUS_MAPPING[params[:status]]
  end

  def error_occurred?
    params[:error_code].present? && status == 'failed'
  end

  def external_error
    return nil unless error_occurred?

    params[:error_code]
  end

  def message
    return if params[:id].blank?

    @message ||= inbox.messages.find_by(source_id: params[:id])
  end
end
