class Migration::CompanyBackfillJob < ApplicationJob
  queue_as :low

  def perform
    Rails.logger.info 'Starting company backfill migration...'
    account_count = 0
    Account.find_in_batches(batch_size: 100) do |accounts|
      accounts.each do |account|
        Rails.logger.info "Enqueuing company backfill for account #{account.id}"
        Migration::CompanyAccountBatchJob.perform_later(account)
        account_count += 1
      end
    end

    Rails.logger.info "Company backfill migration complete. Enqueued jobs for #{account_count} accounts."
  end
end
