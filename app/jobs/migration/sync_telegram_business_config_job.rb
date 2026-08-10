class Migration::SyncTelegramBusinessConfigJob < ApplicationJob
  class RefreshFailed < StandardError; end

  BATCH_SIZE = 100

  queue_as :async_database_migration

  def perform(after_id: 0)
    channels = Channel::Telegram.where('id > ?', after_id).order(:id).limit(BATCH_SIZE + 1).to_a
    batch = channels.first(BATCH_SIZE)
    failed_channel_ids = batch.reject(&:refresh_business_config!).map(&:id)

    raise RefreshFailed, "Telegram Business config refresh failed for channel IDs: #{failed_channel_ids.join(', ')}" if failed_channel_ids.any?

    self.class.perform_later(after_id: batch.last.id) if channels.size > BATCH_SIZE
  end
end
