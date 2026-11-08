module Concerns::TwilioVoiceCredentials
  private

  def reauthorize_and_update_channel(channel_attributes)
    channel = @inbox.channel
    attributes = permitted_params(channel_attributes)[:channel]
    if channel.is_a?(Channel::TwilioSms) && attributes[:voice_enabled] == true
      attributes.require(:auth_token) if channel.api_key_sid.present? && !channel.account_auth_token_configured?
      attributes.require(:api_key_sid) if channel.api_key_sid.blank?
      attributes.require(:api_key_secret) if channel.api_key_secret.blank?
      channel.provider_config = channel.provider_config.merge('account_auth_token_configured' => true)
    end

    super
  end
end
