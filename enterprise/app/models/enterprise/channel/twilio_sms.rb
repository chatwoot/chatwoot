module Enterprise::Channel::TwilioSms
  extend ActiveSupport::Concern

  def self.prepended(base)
    base.class_eval do
      encrypts :api_key_secret if Chatwoot.encryption_configured?

      validate :voice_requires_phone_number, if: :voice_enabled?
      before_validation :provision_twiml_app, on: :create, if: :voice_enabled?
      before_validation :provision_twiml_app_on_update, on: :update, if: :voice_enabled_changed_to_true?
      after_commit :teardown_voice, on: :update, if: :voice_disabled?
    end
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

  # Voice channels store the secret in api_key_secret; SMS channels keep using auth_token via super.
  def client
    if api_key_sid.present? && api_key_secret.present?
      Twilio::REST::Client.new(api_key_sid, api_key_secret, account_sid)
    else
      super
    end
  end

  private

  def voice_requires_phone_number
    return if phone_number.present?

    errors.add(:base, 'Voice calling requires a phone number and cannot be used with messaging service SID')
  end

  def voice_enabled_changed_to_true?
    voice_enabled? && voice_enabled_changed?
  end

  def voice_disabled?
    !voice_enabled? && voice_enabled_previously_changed?
  end

  def teardown_voice
    Twilio::VoiceTeardownService.new(channel: self).perform
  end

  def provision_twiml_app
    return if twiml_app_sid.present?
    return if phone_number.blank?

    validate_voice_capability!
    service = ::Twilio::VoiceWebhookSetupService.new(channel: self)
    self.twiml_app_sid = service.perform
  rescue StandardError => e
    Rails.logger.error("TWILIO_VOICE_SETUP_ERROR: #{e.class} #{e.message} phone=#{phone_number} account=#{account_id}")
    errors.add(:base, "Twilio voice setup failed: #{e.message}")
  end

  def validate_voice_capability!
    number = client.incoming_phone_numbers.list(phone_number: phone_number).first
    raise 'Phone number not found in Twilio account' unless number
    raise 'This phone number does not support voice calls' unless number.capabilities['voice']
  end

  alias provision_twiml_app_on_update provision_twiml_app
end
