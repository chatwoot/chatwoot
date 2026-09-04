class Migration::SyncTelegramBusinessConfigJob < ApplicationJob
  BATCH_SIZE = 100

  queue_as :async_database_migration

  def perform(after_id: 0)
    channels = Channel::Telegram.where('id > ?', after_id).order(:id).limit(BATCH_SIZE + 1).to_a
    batch = channels.first(BATCH_SIZE)
    failed_channel_ids = batch.reject(&:refresh_business_config!).map(&:id)

    failed_channel_ids.each { |channel_id| Migration::SyncTelegramBusinessConfigChannelJob.perform_later(channel_id) }

    self.class.perform_later(after_id: batch.last.id) if channels.size > BATCH_SIZE
  end
end
