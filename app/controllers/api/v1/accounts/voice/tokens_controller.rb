class Api::V1::Accounts::Voice::TokensController < Api::V1::Accounts::BaseController
  before_action :set_voice_inbox

  def create
    render json: build_response
  rescue StandardError => e
    Rails.logger.error("Voice::TokensController#create: #{e.class} - #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    render json: { error: 'Failed to generate token', details: e.message }, status: :internal_server_error
  end

  private

  def build_response
    {
      token:          twilio_token.to_jwt,
      identity:       client_identity,
      voice_enabled:  true,
      account_sid:    twilio_config[:account_sid],
      agent_id:       Current.user.id,
      account_id:     Current.account.id,
      inbox_id:       @voice_inbox.id,
      phone_number:   twilio_config[:phone_number],
      twiml_endpoint: twilio_config[:twiml_url],
      has_twiml_app:  twilio_config[:outgoing_app_sid].present?
    }
  end

  def twilio_token
    Twilio::JWT::AccessToken.new(
      *twilio_credentials,
      identity: client_identity,
      ttl: 1.hour.to_i
    ).tap { |t| t.add_grant(voice_grant) }
  end

  def twilio_credentials
    twilio_config.values_at(:account_sid, :api_key_sid, :api_key_secret)
  end

  def voice_grant
    Twilio::JWT::AccessToken::VoiceGrant.new.tap do |grant|
      grant.incoming_allow = true
      grant.outgoing_application_sid    = twilio_config[:outgoing_app_sid]
      grant.outgoing_application_params = outgoing_params
    end
  end

  def outgoing_params
    {
      account_id:  Current.account.id,
      agent_id:    Current.user.id,
      identity:    client_identity,
      client_name: client_identity,
      accountSid:  twilio_config[:account_sid],
      is_agent:    'true'
    }
  end

  def twilio_config
    @twilio_config ||= begin
      cfg = @voice_inbox.channel.provider_config_hash || {}
      {
        account_sid:      cfg['account_sid'],
        api_key_sid:      cfg['api_key_sid'],
        api_key_secret:   cfg['api_key_secret'],
        outgoing_app_sid: cfg['outgoing_application_sid'],
        phone_number:     @voice_inbox.channel.phone_number,
        twiml_url:        "#{ENV.fetch('FRONTEND_URL', '')}/twilio/voice/call/#{@voice_inbox.channel.phone_number.delete_prefix('+')}"
      }.with_indifferent_access.merge(client_identity:)
    end
  end

  def client_identity
    @client_identity ||= "agent-#{Current.user.id}-account-#{Current.account.id}"
  end

  def set_voice_inbox
    @voice_inbox = Current.account.inboxes.find(params[:inbox_id])
  end
end
