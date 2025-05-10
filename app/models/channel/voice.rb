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

  def initiate_call(to:, conference_name: nil, agent_id: nil)
    case provider
    when 'twilio'
      initiate_twilio_call(to, conference_name, agent_id)
    # Add more providers as needed
    # when 'other_provider'
    #   initiate_other_provider_call(to)
    else
      raise "Unsupported voice provider: #{provider}"
    end
  end

  private

  def initiate_twilio_call(to, conference_name = nil, agent_id = nil)
    config = provider_config_hash

    # Generate a public URL for Twilio to request TwiML (must set FRONTEND_URL)
    host = ENV.fetch('FRONTEND_URL')

    # Use the simplest possible TwiML endpoint
    callback_url = "#{host}/twilio/voice/simple"

    # Start building query parameters
    query_params = []

    # Make sure conference_name is URL-safe and correctly formatted
    if conference_name.present?
      # Check format - it should be like 'conf_account_123_conv_456'
      if !conference_name.match?(/^conf_account_\d+_conv_\d+$/)
        # If format is wrong, log an error and try to fix it
        Rails.logger.error("🚨 MALFORMED CONFERENCE NAME: '#{conference_name}'")

        # Try to extract account_id and conversation_id from the string if possible
        if conference_name.include?('_account_') && conference_name.include?('_conv_')
          # It has the parts but wrong format, let's try to keep it
          Rails.logger.info("🔄 Using conference name as-is: '#{conference_name}'")
        else
          # Can't salvage it, generate a placeholder with timestamp to avoid collisions
          timestamp = Time.now.to_i
          Rails.logger.warn("🚨 GENERATING PLACEHOLDER CONFERENCE NAME with timestamp #{timestamp}")
          conference_name = "conf_placeholder_#{timestamp}"
        end
      else
        # Format looks good, continue
        Rails.logger.info("✅ VALIDATED CONFERENCE NAME: '#{conference_name}'")
      end

      # Add URL-encoded conference name as a parameter
      query_params << "conference_name=#{CGI.escape(conference_name)}"
    else
      # No conference name provided, log this as a warning
      Rails.logger.warn("⚠️ NO CONFERENCE NAME PROVIDED for outgoing call to #{to}")
    end

    # Add agent ID as a parameter if provided
    query_params << "agent_id=#{agent_id}" if agent_id.present?

    # Append query parameters to URL if any exist
    if query_params.any?
      callback_url += "?#{query_params.join('&')}"
      Rails.logger.info("📞 OUTBOUND CALL: Using callback URL with params: #{callback_url}")
    end

    # Parameters including status callbacks for call progress tracking
    params = {
      from: phone_number,
      to: to,
      url: callback_url,
      status_callback: "#{host}/twilio/voice/status_callback",
      status_callback_event: %w[initiated ringing answered completed failed busy no-answer canceled],
      status_callback_method: 'POST'
    }

    # Log the full parameters for debugging
    Rails.logger.info("📞 OUTBOUND CALL PARAMS: to=#{to}, from=#{phone_number}, conference=#{conference_name}")

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
      conference_name: conference_name # Include the conference name in the return value for debugging
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
