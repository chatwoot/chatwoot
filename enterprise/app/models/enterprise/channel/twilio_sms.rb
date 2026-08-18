module Enterprise::Channel::TwilioSms
  extend ActiveSupport::Concern

  def self.prepended(base)
    base.class_eval do
      encrypts :api_key_secret if Chatwoot.encryption_configured?

      validate :voice_requires_phone_number, if: :voice_enabled?
    end
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
end
