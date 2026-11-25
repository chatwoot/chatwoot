class Contacts::SyncGroupJob < ApplicationJob
  queue_as :default

  SYNC_COOLDOWN = 15.minutes

  # `channel` is the inbox the sync was asked for. Without it the service falls back to
  # `Contact#group_channel`, which picks the group contact's first contact_inbox: an
  # arbitrary choice as soon as the same WhatsApp group is in two inboxes of one
  # account, and the sync can then run through a session that is not even connected.
  def perform(contact, force: false, soft: false, channel: nil)
    return if !force && recently_synced?(contact)

    Contacts::SyncGroupService.new(contact: contact, soft: soft, channel: channel).perform
  rescue Whatsapp::Session::Errors::ProviderUnavailable => e
    Rails.logger.error "SyncGroupJob failed for contact #{contact.id}: #{e.message}"
  end

  private

  def recently_synced?(contact)
    last_synced = contact.additional_attributes&.dig('group_last_synced_at')
    return false if last_synced.blank?

    Time.zone.at(last_synced) > SYNC_COOLDOWN.ago
  end
end
