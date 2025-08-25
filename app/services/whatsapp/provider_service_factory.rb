# frozen_string_literal: true

module Whatsapp
  class ProviderServiceFactory
    def self.create(channel)
      provider = channel.provider || 'default'

      case provider
      when 'whatsapp_cloud'
        Whatsapp::Providers::WhatsappCloudService.new(whatsapp_channel: channel)
      when 'whapi'
        Whatsapp::Providers::WhapiService.new(whatsapp_channel: channel)
      else
        # 'default' and any other provider maps to 360Dialog
        Whatsapp::Providers::Whatsapp360DialogService.new(whatsapp_channel: channel)
      end
    rescue StandardError => e
      Rails.logger.error "Failed to create provider service for #{provider}: #{e.message}"
      # Fallback to default provider
      Whatsapp::Providers::Whatsapp360DialogService.new(whatsapp_channel: channel)
    end
  end
end