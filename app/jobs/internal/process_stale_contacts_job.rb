# housekeeping
# remove stale contacts for subset of accounts each day
# - have no identification (email, phone_number, and identifier are NULL)
# - have no conversations
# - are older than 30 days

class Internal::ProcessStaleContactsJob < ApplicationJob
  queue_as :housekeeping

  # Number of day-based groups to split accounts into
  DISTRIBUTION_GROUPS = 5
  # Max accounts to process in one batch
  MAX_ACCOUNTS_PER_BATCH = 20

  # Process only a subset of accounts per day to avoid flooding the queue
  def perform
    return unless ChatwootApp.chatwoot_cloud?

    # Use the day of the month to determine which accounts to process
    day_of_month = Date.current.day
    remainder = day_of_month % DISTRIBUTION_GROUPS

    # Count total accounts for logging
    total_accounts = Account.count
    log_message = "ProcessStaleContactsJob: Processing accounts with ID % #{DISTRIBUTION_GROUPS} = "
    log_message += "#{remainder} (out of #{total_accounts} total accounts)"
    Rails.logger.info log_message

    # Process only accounts where ID % 5 = remainder for today
    # This ensures each account is processed approximately once every 5 days
    Account.where("id % #{DISTRIBUTION_GROUPS} = ?", remainder).find_each(batch_size: MAX_ACCOUNTS_PER_BATCH) do |account|
      Rails.logger.info "Enqueuing RemoveStaleContactsJob for account #{account.id}"

      # Add a small delay between jobs to further reduce queue pressure
      delay = rand(1..10).minutes
      Internal::RemoveStaleContactsJob.set(wait: delay).perform_later(account)
    end
  end
end
