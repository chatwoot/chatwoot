# housekeeping
# remove stale contacts for all accounts
# - have no identification (email, phone_number, and identifier are NULL)
# - have no conversations
# - are older than 30 days

class Internal::ProcessStaleContactsJob < ApplicationJob
  queue_as :scheduled_jobs

  ACCOUNTS_PER_DAY = 5000

  def perform
    return unless ChatwootApp.chatwoot_cloud?

    # Use day of week (0-6) to determine which accounts to process today
    day_offset = Time.current.wday * ACCOUNTS_PER_DAY

    Account.order(:id).offset(day_offset).limit(ACCOUNTS_PER_DAY).find_each do |account|
      Rails.logger.info "Enqueuing RemoveStaleContactsJob for account #{account.id}"
      # Add a small delay between jobs to prevent queue overload
      Internal::RemoveStaleContactsJob.set(wait: 5.seconds).perform_later(account)
    end
  end
end
