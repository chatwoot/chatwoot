module TwilioMessagingSignatureVerification
  extend ActiveSupport::Concern
  include TwilioWebhookVerification

  included do
    before_action :verify_twilio_messaging_signature!
  end

  private

  # Channels start in log-only mode and switch to enforced on their first request that carries a valid signature.
  def verify_twilio_messaging_signature!
    channel = twilio_channel
    return if channel.blank?
    return log_unverifiable_twilio_channel(channel) unless twilio_signature_verifiable?(channel)
    return enforce_twilio_signature!(channel) if signed_by_twilio?(channel)

    log_invalid_twilio_signature(channel)
    head :forbidden if channel.webhook_signature_enforced?(controller_name)
  end

  # API key channels store the key secret in auth_token, which Twilio does not sign with.
  def twilio_signature_verifiable?(channel)
    channel.api_key_sid.blank? || channel.try(:account_auth_token_configured?)
  end

  def signed_by_twilio?(channel)
    twilio_signature_urls.any? { |url| valid_twilio_signature?(channel.auth_token, url) }
  end

  def twilio_signature_urls
    registered_url = URI(twilio_webhook_url)
    registered_url.query = request.query_string.presence
    [request.original_url, registered_url.to_s].uniq
  end

  def enforce_twilio_signature!(channel)
    channel.enforce_webhook_signature!(controller_name) unless channel.webhook_signature_enforced?(controller_name)
  end

  def log_unverifiable_twilio_channel(channel)
    Rails.logger.info("[TWILIO] Signature not verified, account auth token not configured channel_id=#{channel.id}")
  end

  def log_invalid_twilio_signature(channel)
    Rails.logger.warn(
      "[TWILIO] Invalid webhook signature channel_id=#{channel.id} endpoint=#{controller_name} " \
      "enforced=#{channel.webhook_signature_enforced?(controller_name)} url=#{request.original_url}"
    )
  end
end
