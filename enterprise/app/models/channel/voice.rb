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
  include Rails.application.routes.url_helpers

  self.table_name = 'channel_voice'

  validates :phone_number, presence: true, uniqueness: true
  validates :provider, presence: true
  validates :provider_config, presence: true

  # Validate phone number format (E.164 format)
  validates :phone_number, format: { with: /\A\+[1-9]\d{1,14}\z/ }

  # Provider-specific configs stored in JSON
  validate :validate_provider_config

  EDITABLE_ATTRS = [:phone_number, :provider, { provider_config: {} }].freeze

  def name
    "Voice (#{phone_number})"
  end

  def messaging_window_enabled?
    false
  end

  def initiate_call(to:, conference_sid: nil, agent_id: nil)
    case provider
    when 'twilio'
      initiate_twilio_call(to, conference_sid, agent_id)
    # Add more providers as needed
    # when 'other_provider'
    #   initiate_other_provider_call(to)
    else
      raise "Unsupported voice provider: #{provider}"
    end
  end

  private

  def validate_provider_config
    return if provider_config.blank?

    case provider
    when 'twilio'
      validate_twilio_config
    end
  end

  def validate_twilio_config
    config = provider_config.with_indifferent_access
    required_keys = %w[account_sid auth_token api_key_sid api_key_secret]

    required_keys.each do |key|
      errors.add(:provider_config, "#{key} is required for Twilio provider") if config[key].blank?
    end
  end

  def initiate_twilio_call(to, conference_sid = nil, agent_id = nil)
    config = provider_config_hash

    # Generate a public URL for Twilio to request TwiML (must set FRONTEND_URL)
    host = ENV.fetch('FRONTEND_URL')

    # Use phone-scoped TwiML endpoint for this inbox
    phone_digits = phone_number.delete_prefix('+')
    callback_url = "#{host}/twilio/voice/call/#{phone_digits}"

    # Parameters including status callbacks for call progress tracking
    params = {
      from: phone_number,
      to: to,
      url: callback_url,
      status_callback: "#{host}/twilio/voice/status/#{phone_digits}",
      status_callback_event: %w[initiated ringing answered completed failed busy no-answer canceled],
      status_callback_method: 'POST'
    }

    # Log the full parameters for debugging
    Rails.logger.info("📞 OUTBOUND CALL PARAMS: to=#{to}, from=#{phone_number}, conference=#{conference_sid}")

    # Create the call
    call = twilio_client(config).calls.create(**params)

    # Return info needed to properly route and track the call
    {
      provider: 'twilio',
      call_sid: call.sid,
      status: call.status,
      call_direction: 'outbound',  # CRITICAL: Tag as outbound so webhooks know to prompt agent
      requires_agent_join: true,   # Flag that agent should join immediately
      agent_id: agent_id,          # Include agent_id for tracking who initiated the call
      conference_sid: conference_sid # Include the conference name in the return value for debugging
    }
  end

  def twilio_client(config)
    Twilio::REST::Client.new(config['account_sid'], config['auth_token'])
  end

  def provider_config_hash
    if provider_config.is_a?(Hash)
      provider_config
    else
      JSON.parse(provider_config.to_s)
    end
  end

  public :provider_config_hash
end
