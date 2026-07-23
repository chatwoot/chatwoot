# Keeps the Coro Inbox WhatsApp Cloud api_key in sync with the Meta token
# owned by company-chat (Dualhook). Set WHATSAPP_META_ACCESS_TOKEN on Railway
# to the same value as company-chat's Vercel env.
class Msh::SyncWhatsappTokenJob < ApplicationJob
  queue_as :low

  # MSH desk number — Meta is connected via company-chat Dualhook, not Chatwoot.
  MSH_PHONE_NUMBER = '+971558992235'

  def perform
    token = ENV['WHATSAPP_META_ACCESS_TOKEN'].presence
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
end
