class Schedulers::SyncScheduledMessagesJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Account.find_each(batch_size: 50) do |account|
      next unless account.feature_enabled?(:scheduler)

      Schedulers::SyncService.new(account).perform
    rescue StandardError => e
      Rails.logger.error "Scheduler sync failed for account #{account.id}: #{e.message}"
    end
  end
end
