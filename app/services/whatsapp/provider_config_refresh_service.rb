class Whatsapp::ProviderConfigRefreshService
  def initialize(whatsapp_channel, whatsapp_app_id: nil)
    @whatsapp_channel = whatsapp_channel
    @whatsapp_app_id = whatsapp_app_id
  end

  def perform
    return failure('Channel is not a WhatsApp Cloud API channel') unless whatsapp_cloud_channel?
    return failure('WHATSAPP_APP_ID is not configured in Chatwit') if app_id.blank?

    provider_config = (@whatsapp_channel.provider_config || {}).merge('whatsapp_app_id' => app_id)
    # This refresh only persists local Meta identifiers; validating the API token would
    # make the config repair depend on a live Graph API call.
    @whatsapp_channel.assign_attributes(provider_config: provider_config)
    @whatsapp_channel.save!(validate: false)

    {
      success: true,
      whatsapp_app_id: app_id,
      provider_config: provider_config.slice('business_account_id', 'phone_number_id', 'whatsapp_app_id')
    }
  end

  private

  def whatsapp_cloud_channel?
    @whatsapp_channel.is_a?(Channel::Whatsapp) && @whatsapp_channel.provider == 'whatsapp_cloud'
  end

  def app_id
    @app_id ||= @whatsapp_app_id.presence || Whatsapp::AppIdResolver.new(@whatsapp_channel).find
  end

  def failure(message)
    { success: false, error: message }
  end
end
