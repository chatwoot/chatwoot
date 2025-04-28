class Channel::Voice < ApplicationRecord
  include Channelable
  include Rails.application.routes.url_helpers

  self.table_name = 'channel_voice'

  validates :phone_number, presence: true, uniqueness: true
  validates :provider, presence: true

  # Provider-specific configs stored in JSON
  validates :provider_config, presence: true

  EDITABLE_ATTRS = [:phone_number, :provider, :provider_config].freeze

  def name
    "#{provider.capitalize} Voice"
  end

  def initiate_call(to:)
    case provider
    when 'twilio'
      initiate_twilio_call(to)
    # Add more providers as needed
    # when 'other_provider'
    #   initiate_other_provider_call(to)
    else
      raise "Unsupported voice provider: #{provider}"
    end
  end

  private

  def initiate_twilio_call(to)
    config = provider_config_hash

    # Generate a full URL for Twilio to request TwiML
    host = ENV.fetch('FRONTEND_URL', 'http://localhost:3000')

    # Use the simplest possible TwiML endpoint
    callback_url = "#{host}/twilio/voice/simple"

    # Parameters including status callbacks for call progress tracking
    params = {
      from: phone_number,
      to: to,
      url: callback_url,
      status_callback: "#{host}/twilio/voice/status_callback",
      status_callback_event: %w[initiated ringing answered completed],
      status_callback_method: 'POST'
    }

    # Create the call
    call = twilio_client(config).calls.create(**params)

    # Return the bare minimum
    {
      provider: 'twilio',
      call_sid: call.sid,
      status: call.status
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
