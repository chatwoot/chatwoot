# Fetches a contact's WhatsApp profile picture. Enqueued whenever a contact is seen
# without an avatar, so the dashboard fills in over time instead of blocking the
# message that introduced the contact.
class Whatsapp::Session::UpdateContactAvatarJob < ApplicationJob
  queue_as :low

  # A session that is down or throttled will answer later. Swallowing that leaves the
  # stored avatar in place, and the ordinary message path will not ask again while an
  # avatar is attached, so a forced refresh dropped here is stale forever.
  retry_on Whatsapp::Session::Errors::ProviderUnavailable, wait: :polynomially_longer, attempts: 4
  retry_on Whatsapp::Session::Errors::RateLimited, wait: :polynomially_longer, attempts: 4

  # `party` is a serialized Model::Party. `force` is the picture-changed event, which
  # knows the stored avatar is out of date and must refetch over it.
  def perform(contact, inbox, party, force: false)
    return if contact.avatar.attached? && !force

    channel = inbox.channel
    return unless channel.session_capabilities.include?('profile_picture')

    # The command declares an Address, and building it with `new` runs no coercion, so
    # handing it a Party would put the wrong shape on the wire and break every backend
    # that reads the address.
    address = Whatsapp::Session::Model::Party.from_h(party).address
    url = channel.session_backend.profile_picture_url(
      Whatsapp::Session::Model::Commands::ContactProfilePicture.new(party: address)
    )
    # Dated, so a picture-removed event landing between this lookup and the download
    # wins: `Avatar::AvatarFromUrlJob` compares the two and drops a URL the contact has
    # already taken down.
    ::Avatar::AvatarFromUrlJob.perform_later(contact, url, resolved_at: Time.current.iso8601) if url.present?
  rescue Whatsapp::Session::Errors::ProviderUnavailable, Whatsapp::Session::Errors::RateLimited
    # Raised on so the `retry_on` above can see it: a rescue in this method catches the
    # error first, and the retry declaration never runs.
    raise
  rescue Whatsapp::Session::Errors::Error => e
    # What is left here cannot be retried into working: the backend does not support the
    # lookup, the credentials are wrong, or the party has no picture to give.
    Rails.logger.warn("[WHATSAPP SESSION] profile picture failed for contact #{contact.id}: #{e.message}")
  end
end
