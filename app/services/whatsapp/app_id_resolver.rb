class Whatsapp::AppIdResolver
  def initialize(whatsapp_channel = nil)
    @whatsapp_channel = whatsapp_channel
  end

  def find
    global_config_app_id.presence ||
      env_app_id.presence ||
      channel_app_id.presence
  end

  private

  def global_config_app_id
    GlobalConfigService.load('WHATSAPP_APP_ID', '')
  end

  def env_app_id
    ENV.fetch('WHATSAPP_APP_ID', nil).presence ||
      ENV.fetch('META_APP_ID', nil).presence
  end

  def channel_app_id
    provider_config = @whatsapp_channel&.provider_config || {}
    provider_config['whatsapp_app_id'].presence || provider_config['app_id'].presence
  end
end
