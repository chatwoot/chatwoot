class Voice::Provider::Twilio::Adapter
  def initialize(channel)
    @channel = channel
  end

  def initiate_call(to:, conference_sid: nil, agent_id: nil)
    call = twilio_client.calls.create(**call_params(to)) # rubocop:disable Rails/SaveBang

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
    phone_digits = @channel.phone_number.delete_prefix('+')

    {
      from: @channel.phone_number,
      to: to,
      url: twilio_call_twiml_url(phone_digits),
      status_callback: twilio_call_status_url(phone_digits),
      status_callback_event: %w[
        initiated ringing answered completed failed busy no-answer canceled
      ],
      status_callback_method: 'POST'
    }
  end

  def twilio_call_twiml_url(phone_digits)
    Rails.application.routes.url_helpers.twilio_voice_call_url(phone: phone_digits)
  end

  def twilio_call_status_url(phone_digits)
    Rails.application.routes.url_helpers.twilio_voice_status_url(phone: phone_digits)
  end

  def twilio_client
    Twilio::REST::Client.new(config['account_sid'], config['auth_token'])
  end

  def config
    @config ||= @channel.provider_config_hash
  end
end
