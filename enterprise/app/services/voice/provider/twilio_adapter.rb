class Voice::Provider::TwilioAdapter
  def initialize(channel)
    @channel = channel
  end

  def initiate_call(to:, _conference_sid: nil, _agent_id: nil)
    cfg = @channel.provider_config_hash

    host = ENV.fetch('FRONTEND_URL')
    phone_digits = @channel.phone_number.delete_prefix('+')
    callback_url = "#{host}/twilio/voice/call/#{phone_digits}"

    params = {
      from: @channel.phone_number,
      to: to,
      url: callback_url,
      status_callback: "#{host}/twilio/voice/status/#{phone_digits}",
      status_callback_event: %w[initiated ringing answered completed],
      status_callback_method: 'POST'
    }

    call = twilio_client(cfg).calls.create(**params)

    { call_sid: call.sid }
  end

  private

  def twilio_client(config)
    Twilio::REST::Client.new(config['account_sid'], config['auth_token'])
  end
end
