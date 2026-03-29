class Schedulers::DispatchScheduledMessagesJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Account.find_each(batch_size: 50) do |account|
      next unless account.feature_enabled?(:scheduler)

      Schedulers::DispatchService.new(account).perform
    rescue StandardError => e
      Rails.logger.error "Scheduler dispatch failed for account #{account.id}: #{e.message}"
    end
  end
end
