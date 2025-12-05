class Whatsapp::FetchContactAvatarJob < ApplicationJob
  queue_as :low

  # Retry configuration for avatar fetch failures
  # We retry fewer times than critical operations since avatar is non-essential
  retry_on Errno::ECONNREFUSED, wait: :polynomially_longer, attempts: 2
  retry_on Net::OpenTimeout, wait: :polynomially_longer, attempts: 2
  retry_on Net::ReadTimeout, wait: :polynomially_longer, attempts: 2

  def perform(contact_id, inbox_id, identifier)
    contact = Contact.find_by(id: contact_id)
    inbox = Inbox.find_by(id: inbox_id)

    return unless contact && inbox

    # Skip if avatar was recently updated (within last 24 hours)
    if contact.avatar.attached? && contact.updated_at > 24.hours.ago
      Rails.logger.debug { "WhatsApp Web: Contact #{contact_id} has recent avatar, skipping fetch" }
      return
    end

    # Fetch avatar URL from gateway
    avatar_url = inbox.channel.avatar_url(identifier)

    # Enqueue avatar download job if URL is available
    ::Avatar::AvatarFromUrlJob.perform_later(contact, avatar_url) if avatar_url.present?

    Rails.logger.info(
      "WhatsApp Web: Avatar fetch job completed successfully for contact #{contact_id}"
    )
  rescue StandardError => e
    Rails.logger.error(
      "WhatsApp Web: Avatar fetch job failed for contact #{contact_id}: #{e.message}"
    )
    # Re-raise to trigger retry mechanism
    raise e
  end
end
