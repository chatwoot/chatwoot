# Refetches a group photo. `force` is what a picture-changed event needs: the avatar is
# attached, but it is the old one.
class Whatsapp::Session::UpdateGroupAvatarJob < ApplicationJob
  queue_as :low

  # Same reason as the contact job: a forced refresh dropped because the session was
  # momentarily down leaves the old picture, and nothing asks again while it is attached.
  retry_on Whatsapp::Session::Errors::ProviderUnavailable, wait: :polynomially_longer, attempts: 4
  retry_on Whatsapp::Session::Errors::RateLimited, wait: :polynomially_longer, attempts: 4

  # `channel` is the inbox the event came from. Falling back to `group_channel` picks
  # the group contact's first contact_inbox, which is an arbitrary choice as soon as the
  # same WhatsApp group is in two inboxes of one account: the picture could then be
  # asked of a provider that is not even connected.
  def perform(group_contact, force: false, channel: nil)
    return unless refetch?(group_contact, force)

    channel ||= group_contact.group_channel
    return if channel.blank?

    info = fetch_info(channel, group_contact)
    return if info&.picture_url.blank?

    return Whatsapp::Session::AvatarSync.refetch(group_contact, info.picture_url) if force

    ::Avatar::AvatarFromUrlJob.perform_later(group_contact, info.picture_url, resolved_at: Time.current.iso8601)
  end

  private

  def refetch?(group_contact, force)
    force || !group_contact.avatar.attached?
  end

  def fetch_info(channel, group_contact)
    address = Whatsapp::Session::Model::Address.parse(group_contact.identifier)
    return if address.blank?

    channel.session_backend.group_info(Whatsapp::Session::Model::Commands::GroupInfo.new(group: address))
  rescue Whatsapp::Session::Errors::ProviderUnavailable, Whatsapp::Session::Errors::RateLimited
    # Raised on, not swallowed: the job retries and the retry is what keeps a forced
    # refresh from leaving the old picture attached for good.
    raise
  rescue Whatsapp::Session::Errors::Error => e
    Rails.logger.warn("[WHATSAPP SESSION] group photo failed for contact #{group_contact.id}: #{e.message}")
    nil
  end
end
