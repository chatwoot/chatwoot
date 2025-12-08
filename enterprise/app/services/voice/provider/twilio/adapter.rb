class Voice::Provider::Twilio::Adapter
  def initialize(channel)
    @channel = channel
  end

  def initiate_call(to:, conference_sid: nil, agent_id: nil)
    call = twilio_client.calls.create(**call_params(to))

    {
      provider: 'twilio',
      call_sid: call.sid,
      status: call.status,
      call_direction: 'outbound',
      requires_agent_join: true,
      agent_id: agent_id,
      conference_sid: conference_sid
    }
  end

  private

  def call_params(to)
    host = callback_host
    phone_digits = @channel.phone_number.delete_prefix('+')

    {
      from: @channel.phone_number,
      to: to,
      url: "#{host}/twilio/voice/call/#{phone_digits}",
      status_callback: "#{host}/twilio/voice/status/#{phone_digits}",
      status_callback_event: %w[
        initiated ringing answered completed failed busy no-answer canceled
      ],
      status_callback_method: 'POST'
    }
  end

  def callback_host
    ENV.fetch('FRONTEND_URL')
  end

  def twilio_client
    Twilio::REST::Client.new(config['account_sid'], config['auth_token'])
  end

  def config
    @config ||= @channel.provider_config_hash
  end
end
