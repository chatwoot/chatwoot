# housekeeping
# remove stale contacts for all accounts
# - have no identification (email, phone_number, and identifier are NULL)
# - have no conversations
# - are older than 30 days

class Internal::ProcessStaleContactsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Account.find_in_batches(batch_size: 100) do |accounts|
      accounts.each do |account|
        Rails.logger.info "Enqueuing RemoveStaleContactsJob for account #{account.id}"
        Internal::RemoveStaleContactsJob.perform_later(account)
      end
    end
  end
end
