# Fetches a WhatsApp contact's profile picture via the Cloud API.
#
# The WhatsApp Cloud API profile picture availability depends on the contact's
# privacy settings — many users restrict it to "My Contacts" or "Nobody".
# This job silently fails when the picture is unavailable.
class Avatar::AvatarFromWhatsappJob < ApplicationJob
  queue_as :purgable

  RATE_LIMIT_WINDOW = 1.day

  def perform(contact, channel)
    return unless channel.provider == 'whatsapp_cloud'

    phone_number = contact.phone_number&.delete('+')
    return if phone_number.blank?
    return if within_rate_limit?(contact)

    profile_pic_url = fetch_profile_picture_url(channel, phone_number)
    return if profile_pic_url.blank?

    Avatar::AvatarFromUrlJob.perform_later(contact, profile_pic_url)
  rescue StandardError => e
    Rails.logger.info "[WHATSAPP AVATAR] Could not fetch profile picture for #{phone_number}: #{e.message}"
  end

  private

  def within_rate_limit?(contact)
    last_sync = contact.additional_attributes&.dig('whatsapp_avatar_checked_at')
    return false if last_sync.blank?

    Time.zone.parse(last_sync) > RATE_LIMIT_WINDOW.ago
  rescue ArgumentError
    false
  end

  def fetch_profile_picture_url(channel, phone_number)
    api_base = ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
    api_version = GlobalConfigService.load('WHATSAPP_API_VERSION', 'v22.0')
    phone_number_id = channel.provider_config['phone_number_id']
    api_key = channel.provider_config['api_key']

    response = HTTParty.get(
      "#{api_base}/#{api_version}/#{phone_number_id}/contacts",
      headers: { 'Authorization' => "Bearer #{api_key}", 'Content-Type' => 'application/json' },
      body: { blocking: 'wait', contacts: ["+#{phone_number}"] }.to_json
    )

    update_check_timestamp(contact_for_update(phone_number, channel))

    return nil unless response.success?

    response.parsed_response&.dig('contacts', 0, 'profile_pic')
  end

  def contact_for_update(phone_number, channel)
    Contact.joins(:contact_inboxes).find_by(
      contact_inboxes: { inbox_id: channel.inbox.id },
      phone_number: "+#{phone_number}"
    )
  end

  def update_check_timestamp(contact)
    return if contact.blank?

    attrs = (contact.additional_attributes || {}).merge('whatsapp_avatar_checked_at' => Time.current.iso8601)
    contact.update!(additional_attributes: attrs)
  end
end
