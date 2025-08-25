# frozen_string_literal: true

module Whatsapp
  class ProviderConfigFactory
    def self.create(channel)
      provider = channel.provider || 'default'

      case provider
      when 'whatsapp_cloud'
        Whatsapp::ProviderConfig::WhatsappCloud.new(channel)
      when 'whapi'
        Whatsapp::ProviderConfig::Whapi.new(channel)
      else
        # 'default' and any other provider maps to 360Dialog
        Whatsapp::ProviderConfig::Whatsapp360Dialog.new(channel)
      end
    rescue StandardError => e
      Rails.logger.error "Failed to create provider config for #{provider}: #{e.message}"
      # Fallback to default provider
      Whatsapp::ProviderConfig::Whatsapp360Dialog.new(channel)
    end
  end
end