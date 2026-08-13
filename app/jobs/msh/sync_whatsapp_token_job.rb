# Keeps the Coro Inbox WhatsApp Cloud api_key in sync with Dualhook.
# Only writes dh_live_ keys so a Meta Graph token in WHATSAPP_META_ACCESS_TOKEN
# cannot overwrite Dualhook inbox credentials.
class Msh::SyncWhatsappTokenJob < ApplicationJob
  queue_as :low

  # MSH desk number — Meta is connected via company-chat Dualhook, not Chatwoot.
  MSH_PHONE_NUMBER = '+971558992235'

  def perform
    token = dualhook_token
    return if token.blank?

    Channel::Whatsapp.where(phone_number: MSH_PHONE_NUMBER).find_each do |channel|
      current = channel.provider_config['api_key'].to_s
      next if current == token

      config = channel.provider_config.deep_dup
      config['api_key'] = token
      # Skip validations/callbacks so we never re-register Meta webhooks away from Dualhook.
      channel.update_columns(provider_config: config, updated_at: Time.current)
      Rails.logger.info("[Msh::SyncWhatsappTokenJob] synced api_key for channel=#{channel.id}")
    end
  end

  private

  def dualhook_token
    [ENV['WHATSAPP_DUALHOOK_API_KEY'], ENV['WHATSAPP_META_ACCESS_TOKEN']].find do |value|
      value.to_s.start_with?('dh_live_')
    end
  end
end
