class Twilio::DeliveryStatusService
  pattr_initialize [:params!]
  # Reference: https://www.twilio.com/docs/messaging/api/message-resource#message-status-values

  def perform
    return if twilio_channel.blank?

    return unless supported_status?

    process_statuses if message.present?
  end

  private

  def process_statuses
    @message.status = status
    @message.external_error = external_error if error_occurred?
    @message.save!
  end

  def supported_status?
    %w[sent delivered read failed undelivered].include?(params[:MessageStatus])
  end

  def status
    params[:MessageStatus] == 'undelivered' ? 'failed' : params[:MessageStatus]
  end

  def external_error
    return nil unless error_occurred?

    error_message = params[:ErrorMessage].presence
    error_code = params[:ErrorCode]

    if error_message.present?
      "#{error_code} - #{error_message}"
    elsif error_code.present?
      I18n.t('conversations.messages.delivery_status.error_code', error_code: error_code)
    end
  end

  def error_occurred?
    params[:ErrorCode].present? && %w[failed undelivered].include?(params[:MessageStatus])
  end

  def twilio_channel
    @twilio_channel ||= if params[:MessagingServiceSid].present?
                          ::Channel::TwilioSms.find_by(messaging_service_sid: params[:MessagingServiceSid])
                        elsif params[:AccountSid].present? && params[:From].present?
                          ::Channel::TwilioSms.find_by!(account_sid: params[:AccountSid], phone_number: params[:From])
                        end
  end

  def message
    return unless params[:MessageSid]

    @message ||= twilio_channel.inbox.messages.find_by(source_id: params[:MessageSid])
  end
end
