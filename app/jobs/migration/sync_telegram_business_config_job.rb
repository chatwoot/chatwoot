class Migration::SyncTelegramBusinessConfigJob < ApplicationJob
  BATCH_SIZE = 100

  queue_as :async_database_migration

  def perform(after_id: 0)
    channels = Channel::Telegram.where('id > ?', after_id).order(:id).limit(BATCH_SIZE + 1).to_a
    batch = channels.first(BATCH_SIZE)

    batch.each(&:refresh_business_config!)
    self.class.perform_later(after_id: batch.last.id) if channels.size > BATCH_SIZE
  end
end
