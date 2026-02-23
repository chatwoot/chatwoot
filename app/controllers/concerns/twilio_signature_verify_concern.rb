module TwilioSignatureVerifyConcern
  extend ActiveSupport::Concern

  included do
    before_action :verify_twilio_signature!
  end

  private

  def verify_twilio_signature!
    channel = find_twilio_channel
    return head :forbidden if channel.blank?

    if channel.api_key_sid.present?
      Rails.logger.warn(
        '[TWILIO] Signature validation skipped: channel uses API key authentication. ' \
        "account_sid=#{params[:AccountSid]} channel_id=#{channel.id}"
      )
      return
    end

    validator = Twilio::Security::RequestValidator.new(channel.auth_token)
    signature = request.headers['X-Twilio-Signature'] || ''
    request_url = reconstruct_url

    return if validator.validate(request_url, request.request_parameters, signature)

    Rails.logger.warn(
      '[TWILIO] Signature validation failed ' \
      "account_sid=#{params[:AccountSid]} " \
      "url=#{request_url}"
    )
    head :forbidden
  end

  def find_twilio_channel
    if params[:MessagingServiceSid].present?
      ::Channel::TwilioSms.find_by(messaging_service_sid: params[:MessagingServiceSid])
    elsif params[:AccountSid].present?
      phone = params[:To].presence || params[:From].presence
      ::Channel::TwilioSms.find_by(account_sid: params[:AccountSid], phone_number: phone) if phone.present?
    end
  end

  def reconstruct_url
    url = request.original_url
    url = url.sub('http://', 'https://') if request.headers['X-Forwarded-Proto'] == 'https' && url.start_with?('http://')
    url
  end
end
