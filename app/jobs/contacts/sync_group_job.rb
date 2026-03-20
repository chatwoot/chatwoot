class Contacts::SyncGroupJob < ApplicationJob
  queue_as :default

  SYNC_COOLDOWN = 15.minutes

  def perform(contact, force: false, soft: false)
    return if !force && recently_synced?(contact)

    Contacts::SyncGroupService.new(contact: contact, soft: soft).perform
  rescue Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError => e
    Rails.logger.error "SyncGroupJob failed for contact #{contact.id}: #{e.message}"
  end

  private

  def recently_synced?(contact)
    last_synced = contact.additional_attributes&.dig('group_last_synced_at')
    return false if last_synced.blank?

    Time.zone.at(last_synced) > SYNC_COOLDOWN.ago
  end
end
