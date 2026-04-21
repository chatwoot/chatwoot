module TwilioSignatureVerifyConcern
  extend ActiveSupport::Concern

  included do
    before_action :verify_twilio_signature!
  end

  private

  def verify_twilio_signature!
    channel = find_twilio_channel
    return log_and_reject_missing_channel if channel.blank?
    return if channel.api_key_sid.present? && log_api_key_skip(channel)

    head :forbidden unless valid_signature?(channel)
  end

  def log_and_reject_missing_channel
    Rails.logger.warn(
      '[TWILIO] Channel not found for webhook ' \
      "account_sid=#{params[:AccountSid]} messaging_service_sid=#{params[:MessagingServiceSid]} " \
      "to=#{params[:To]} from=#{params[:From]}"
    )
    head :forbidden
  end

  def log_api_key_skip(channel)
    Rails.logger.warn(
      '[TWILIO] Signature validation skipped: channel uses API key authentication. ' \
      "account_sid=#{params[:AccountSid]} channel_id=#{channel.id}"
    )
  end

  def valid_signature?(channel)
    signature = request.headers['X-Twilio-Signature']
    if signature.blank?
      Rails.logger.warn("[TWILIO] Missing X-Twilio-Signature header account_sid=#{params[:AccountSid]}")
      return false
    end

    validator = Twilio::Security::RequestValidator.new(channel.auth_token)
    request_url = reconstruct_url
    return true if validator.validate(request_url, request.request_parameters, signature)

    Rails.logger.warn(
      '[TWILIO] Signature validation failed ' \
      "account_sid=#{params[:AccountSid]} channel_id=#{channel.id} url=#{request_url} ip=#{request.remote_ip}"
    )
    false
  end

  def find_twilio_channel
    if params[:MessagingServiceSid].present?
      channel = ::Channel::TwilioSms.find_by(messaging_service_sid: params[:MessagingServiceSid])
      return channel if channel.present? && (params[:AccountSid].blank? || channel.account_sid == params[:AccountSid])

      return nil
    end
    return if params[:AccountSid].blank?

    find_channel_by_phone_number
  end

  def find_channel_by_phone_number
    channel_lookup_phone_numbers.each do |phone|
      channel = ::Channel::TwilioSms.find_by(account_sid: params[:AccountSid], phone_number: phone)
      return channel if channel
    end
    nil
  end

  def channel_lookup_phone_numbers
    [params[:To], params[:From]].compact_blank
  end

  def reconstruct_url
    url = request.original_url
    url = url.sub('http://', 'https://') if url.start_with?('http://') && https_request?
    url
  end

  def https_request?
    return true if request.ssl?

    forwarded_proto = request.headers['X-Forwarded-Proto'].to_s.split(',').map(&:strip).find(&:present?)
    forwarded_proto&.casecmp?('https')
  end
end
