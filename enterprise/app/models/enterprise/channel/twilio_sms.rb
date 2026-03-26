module Enterprise::Channel::TwilioSms
  extend ActiveSupport::Concern

  def self.prepended(base)
    base.class_eval do
      encrypts :api_key_secret if Chatwoot.encryption_configured?

      validate :voice_requires_phone_number, if: :voice_enabled?
      before_validation :provision_twiml_app, on: :create, if: :voice_enabled?
      before_validation :provision_twiml_app_on_update, on: :update, if: :voice_enabled_changed_to_true?
    end
  end

  def voice_enabled?
    voice_enabled
  end

  def initiate_call(to:, conference_sid: nil, agent_id: nil)
    Voice::Provider::Twilio::Adapter.new(self).initiate_call(
      to: to,
      conference_sid: conference_sid,
      agent_id: agent_id
    )
  end

  def voice_call_webhook_url
    digits = phone_number.delete_prefix('+')
    Rails.application.routes.url_helpers.twilio_voice_call_url(phone: digits)
  end

  def voice_status_webhook_url
    digits = phone_number.delete_prefix('+')
    Rails.application.routes.url_helpers.twilio_voice_status_url(phone: digits)
  end

  private

  # Override: when api_key_secret is stored separately (voice channels),
  # use it instead of auth_token for API key authentication.
  # Existing SMS channels store the secret in auth_token — that path is unchanged via super.
  def client
    if api_key_sid.present? && api_key_secret.present?
      Twilio::REST::Client.new(api_key_sid, api_key_secret, account_sid)
    else
      super
    end
  end

  def voice_requires_phone_number
    return if phone_number.present?

    errors.add(:base, 'Voice calling requires a phone number and cannot be used with messaging service SID')
  end

  def voice_enabled_changed_to_true?
    voice_enabled? && voice_enabled_changed?
  end

  def provision_twiml_app
    service = ::Twilio::VoiceWebhookSetupService.new(channel: self)
    self.twiml_app_sid = service.perform
  rescue StandardError => e
    Rails.logger.error("TWILIO_VOICE_SETUP_ERROR: #{e.class} #{e.message} phone=#{phone_number} account=#{account_id}")
    errors.add(:base, "Twilio voice setup failed: #{e.message}")
  end

  alias provision_twiml_app_on_update provision_twiml_app
end
