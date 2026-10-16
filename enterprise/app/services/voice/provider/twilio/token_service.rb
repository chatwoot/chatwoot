class Voice::Provider::Twilio::TokenService
  pattr_initialize [:inbox!, :user!, :account!]

  def generate
    {
      token: access_token.to_jwt,
      identity: identity,
      voice_enabled: true,
      account_sid: channel.account_sid,
      agent_id: user.id,
      account_id: account.id,
      inbox_id: inbox.id,
      phone_number: channel.phone_number,
      twiml_endpoint: twiml_url,
      has_twiml_app: channel.twiml_app_sid.present?
    }
  end

  private

  def channel
    @channel ||= inbox.channel
  end

  def identity
    @identity ||= "agent-#{user.id}-account-#{account.id}"
  end

  def access_token
    Twilio::JWT::AccessToken.new(
      channel.account_sid,
      channel.api_key_sid,
      channel.api_key_secret,
      identity: identity,
      ttl: 1.hour.to_i
    ).tap { |token| token.add_grant(voice_grant) }
  end

  def voice_grant
    Twilio::JWT::AccessToken::VoiceGrant.new.tap do |grant|
      grant.incoming_allow = true
      grant.outgoing_application_sid = channel.twiml_app_sid
      grant.outgoing_application_params = outgoing_params
    end
  end

  def outgoing_params
    {
      account_id: account.id,
      agent_id: user.id,
      identity: identity,
      client_name: identity,
      accountSid: channel.account_sid,
      is_agent: 'true'
    }
  end

  def twiml_url
    digits = channel.phone_number.delete_prefix('+')
    Rails.application.routes.url_helpers.twilio_voice_call_url(phone: digits)
  end
end
