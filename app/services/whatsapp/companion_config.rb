# Installation-wide connection settings for the unofficial (Baileys/QR) WhatsApp
# companion bridge. One companion serves every channel, so the URL and shared
# token are deployment config — managed at Super Admin → Settings → WhatsApp
# Companion (InstallationConfig), with ENV as the docker-compose fallback.
module Whatsapp::CompanionConfig
  module_function

  DEFAULT_COMPANION_URL = 'http://whatsapp-companion:4000'.freeze

  def companion_url
    GlobalConfig.get_value('WHATSAPP_COMPANION_URL').presence ||
      ENV.fetch('WHATSAPP_COMPANION_URL', DEFAULT_COMPANION_URL)
  end

  def companion_token
    GlobalConfig.get_value('WHATSAPP_COMPANION_TOKEN').presence ||
      ENV['WHATSAPP_COMPANION_TOKEN']
  end
end
