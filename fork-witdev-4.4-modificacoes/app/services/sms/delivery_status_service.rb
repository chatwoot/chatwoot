class Sms::DeliveryStatusService
  pattr_initialize [:inbox!, :params!]

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
    %w[message-delivered message-failed].include?(params[:type])
  end

  # Relevant documentation:
  # https://dev.bandwidth.com/docs/mfa/webhooks/international/message-delivered
  # https://dev.bandwidth.com/docs/mfa/webhooks/international/message-failed
  def status
    type_mapping = {
      'message-delivered' => 'delivered',
      'message-failed' => 'failed'
    }

    type_mapping[params[:type]]
  end

  def external_error
    return nil unless error_occurred?

    error_message = params[:description]
    error_code = params[:errorCode]

    "#{error_code} - #{error_message}"
  end

  def error_occurred?
    params[:errorCode] && params[:type] == 'message-failed'
  end

  def message
    return unless params[:message][:id]

    @message ||= inbox.messages.find_by(source_id: params[:message][:id])
  end
end
