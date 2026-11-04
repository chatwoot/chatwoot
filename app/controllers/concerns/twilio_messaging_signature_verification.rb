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
    head :forbidden if twilio_signature_enforced?(channel)
  end

  # API key channels store the key secret in auth_token, which Twilio does not sign with.
  def twilio_signature_verifiable?(channel)
    channel.api_key_sid.blank? || channel.try(:account_auth_token_configured?)
  end

  def signed_by_twilio?(channel)
    [request.original_url, twilio_webhook_url].uniq.any? { |url| valid_twilio_signature?(channel.auth_token, url) }
  end

  def twilio_signature_enforced?(channel)
    channel.provider_config[twilio_signature_enforced_key] == true
  end

  def enforce_twilio_signature!(channel)
    return if twilio_signature_enforced?(channel)

    # rubocop:disable Rails/SkipsModelValidations
    Channel::TwilioSms.where(id: channel.id).update_all(
      ["provider_config = COALESCE(provider_config, '{}'::jsonb) || ?::jsonb", { twilio_signature_enforced_key => true }.to_json]
    )
    # rubocop:enable Rails/SkipsModelValidations
  end

  def twilio_signature_enforced_key
    "#{controller_name}_signature_enforced"
  end

  def log_unverifiable_twilio_channel(channel)
    Rails.logger.info("[TWILIO] Signature not verified, account auth token not configured channel_id=#{channel.id}")
  end

  def log_invalid_twilio_signature(channel)
    Rails.logger.warn(
      "[TWILIO] Invalid webhook signature channel_id=#{channel.id} endpoint=#{controller_name} " \
      "enforced=#{twilio_signature_enforced?(channel)} url=#{request.original_url}"
    )
  end
end
