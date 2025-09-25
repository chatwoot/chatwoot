# == Schema Information
#
# Table name: channel_voice
#
#  id                    :bigint           not null, primary key
#  additional_attributes :jsonb
#  phone_number          :string           not null
#  provider              :string           default("twilio"), not null
#  provider_config       :jsonb            not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :integer          not null
#
# Indexes
#
#  index_channel_voice_on_account_id    (account_id)
#  index_channel_voice_on_phone_number  (phone_number) UNIQUE
#
class Channel::Voice < ApplicationRecord
  include Channelable

  self.table_name = 'channel_voice'

  validates :phone_number, presence: true, uniqueness: true
  validates :provider, presence: true
  validates :provider_config, presence: true

  # Validate phone number format (E.164 format)
  validates :phone_number, format: { with: /\A\+[1-9]\d{1,14}\z/ }

  # Provider-specific configs stored in JSON
  validate :validate_provider_config
  before_validation :provision_twilio_on_create, on: :create, if: :twilio?

  EDITABLE_ATTRS = [:phone_number, :provider, { provider_config: {} }].freeze

  def name
    "Voice (#{phone_number})"
  end

  def messaging_window_enabled?
    false
  end

  # Public URLs used to configure Twilio webhooks
  def voice_call_webhook_url
    digits = phone_number.delete_prefix('+')
    "#{ENV.fetch('FRONTEND_URL', nil)}/twilio/voice/call/#{digits}"
  end

  def voice_status_webhook_url
    digits = phone_number.delete_prefix('+')
    "#{ENV.fetch('FRONTEND_URL', nil)}/twilio/voice/status/#{digits}"
  end

  private

  def twilio?
    provider == 'twilio'
  end

  def validate_provider_config
    return if provider_config.blank?

    case provider
    when 'twilio'
      validate_twilio_config
    end
  end

  def validate_twilio_config
    config = provider_config.with_indifferent_access
    # Require credentials and provisioned TwiML App SID
    required_keys = %w[account_sid auth_token api_key_sid api_key_secret twiml_app_sid]
    required_keys.each do |key|
      errors.add(:provider_config, "#{key} is required for Twilio provider") if config[key].blank?
    end
  end

  def provision_twilio_on_create
    service = ::Twilio::VoiceWebhookSetupService.new(channel: self)
    app_sid = service.perform
    return if app_sid.blank?

    cfg = provider_config.with_indifferent_access
    cfg[:twiml_app_sid] = app_sid
    self.provider_config = cfg
  rescue StandardError => e
    error_details = {
      error_class: e.class.to_s,
      message: e.message,
      phone_number: phone_number,
      account_id: account_id,
      backtrace: e.backtrace&.first(5)
    }
    Rails.logger.error("TWILIO_VOICE_SETUP_ON_CREATE_ERROR: #{error_details}")
    errors.add(:base, "Twilio setup failed: #{e.message}")
  end
end
