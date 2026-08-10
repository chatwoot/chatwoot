class Migration::SyncTelegramBusinessConfigJob < ApplicationJob
  queue_as :async_database_migration

  def perform
    Channel::Telegram.find_each(&:refresh_business_config!)
  end
end
