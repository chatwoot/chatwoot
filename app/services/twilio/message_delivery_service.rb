class Twilio::MessageDeliveryService
  pattr_initialize [:params!]

  def perform
    return if twilio_channel.blank?

    process_statuses if message.present?
  end

  private

  def process_statuses
    # https://www.twilio.com/docs/messaging/api/message-resource#message-status-values
    @message.status = params[:MessageStatus]
    process_error if error_occurred?
    @message.save!
  rescue ArgumentError => e
    Rails.logger.error "Error while processing twilio whatsapp status update #{e.message}"
  end

  def process_error
    @message.external_error = "#{params[:ErrorCode]} - #{params[:ErrorMessage].presence || 'Unknown Error'}"
  end

  def error_occurred?
    %w[failed undelivered].include?(params[:MessageStatus]) && params[:ErrorCode].present?
  end

  def twilio_channel
    @twilio_channel ||= ::Channel::TwilioSms.find_by(messaging_service_sid: params[:MessagingServiceSid]) if params[:MessagingServiceSid].present?
    if params[:AccountSid].present? && params[:From].present?
      @twilio_channel ||= ::Channel::TwilioSms.find_by!(account_sid: params[:AccountSid],
                                                        phone_number: params[:From])
    end
    @twilio_channel
  end

  def message
    return unless params[:MessageSid]

    @message ||= Message.find_by(source_id: params[:MessageSid])
  end
end
