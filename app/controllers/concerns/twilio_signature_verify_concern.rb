module TwilioSignatureVerifyConcern
  extend ActiveSupport::Concern

  included do
    before_action :verify_twilio_signature!
  end

  private

  def verify_twilio_signature!
    channel = find_twilio_channel
    return head :forbidden if channel.blank?
    return if skip_signature_validation?(channel)

    signature = request.headers['X-Twilio-Signature']
    return head :forbidden if reject_blank_signature?(signature)

    validate_signature!(channel, signature)
  end

  def skip_signature_validation?(channel)
    return false if channel.api_key_sid.blank?

    Rails.logger.warn(
      '[TWILIO] Signature validation skipped: channel uses API key authentication. ' \
      "account_sid=#{params[:AccountSid]} channel_id=#{channel.id}"
    )
    true
  end

  def reject_blank_signature?(signature)
    return false if signature.present?

    Rails.logger.warn("[TWILIO] Missing X-Twilio-Signature header account_sid=#{params[:AccountSid]}")
    true
  end

  def validate_signature!(channel, signature)
    if channel.auth_token.blank?
      Rails.logger.error(
        '[TWILIO] Cannot validate signature: auth_token is blank. ' \
        "account_sid=#{params[:AccountSid]} channel_id=#{channel.id}"
      )
      return head :forbidden
    end

    validator = Twilio::Security::RequestValidator.new(channel.auth_token)
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
      find_channel_by_phone_number
    end
  end

  def find_channel_by_phone_number
    [params[:To], params[:From]].compact_blank.each do |phone|
      channel = ::Channel::TwilioSms.find_by(account_sid: params[:AccountSid], phone_number: phone)
      return channel if channel
    end
    nil
  end

  def reconstruct_url
    url = request.original_url
    url = url.sub('http://', 'https://') if request.headers['X-Forwarded-Proto'] == 'https' && url.start_with?('http://')
    url
  end
end
