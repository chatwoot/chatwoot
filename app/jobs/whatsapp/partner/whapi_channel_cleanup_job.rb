class Whatsapp::Partner::WhapiChannelCleanupJob < ApplicationJob
  queue_as :low
  retry_on StandardError, wait: 5.seconds, attempts: 5

  # Deletes the upstream Whapi channel using the Partner API.
  # Arguments:
  # - whapi_channel_id: String
  def perform(whapi_channel_id)
    return if whapi_channel_id.blank?

    service = Whatsapp::Partner::WhapiPartnerService.new
    service.delete_channel(channel_id: whapi_channel_id)
  rescue StandardError => e
    # If the channel is already gone upstream, don't retry.
    if e.message.to_s.include?('404') || e.message.to_s.downcase.include?('not found')
      Rails.logger.info("WhapiChannelCleanupJob: channel_id=#{whapi_channel_id} already deleted upstream; skipping retries")
      return
    end
    Rails.logger.warn("WhapiChannelCleanupJob failed for channel_id=#{whapi_channel_id}: #{e.message}")
    raise
  end
end


