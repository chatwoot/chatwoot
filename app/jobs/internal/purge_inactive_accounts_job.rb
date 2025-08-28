# Job to periodically identify and mark inactive accounts for deletion
# This job should be run regularly (e.g., weekly) to identify inactive accounts
# and mark them for deletion with the "Account Inactive" reason

class Internal::PurgeInactiveAccountsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Rails.logger.info('Starting inactive account purge job')

    inactive_accounts = Internal::InactiveAccountIdentificationService.inactive_accounts
    
    return if inactive_accounts.empty?

    Rails.logger.info("Processing #{inactive_accounts.count} inactive accounts")

    inactive_accounts.find_each do |account|
      mark_account_for_deletion(account)
    end

    Rails.logger.info('Completed inactive account purge job')
  end

  private

  def mark_account_for_deletion(account)
    Rails.logger.info("Marking account #{account.id} (#{account.name}) for deletion due to inactivity")

    if account.mark_for_deletion('Account Inactive')
      Rails.logger.info("Successfully marked account #{account.id} for deletion")
    else
      Rails.logger.error("Failed to mark account #{account.id} for deletion: #{account.errors.full_messages.join(', ')}")
    end
  rescue StandardError => e
    Rails.logger.error("Error marking account #{account.id} for deletion: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
  end
end