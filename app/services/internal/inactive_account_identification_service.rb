# Service to identify inactive accounts for purging
# An account is considered inactive if:
# 1. No user has been active in the last 30 days (based on account_users.active_at)
# 2. No conversations have been created or updated in the last 30 days
# 3. Account is currently active (not suspended)
# 4. Account is not already marked for deletion

class Internal::InactiveAccountIdentificationService
  INACTIVITY_THRESHOLD = InactiveAccountPurge::INACTIVITY_THRESHOLD_DAYS.freeze

  def self.inactive_accounts
    new.inactive_accounts
  end

  def inactive_accounts
    Rails.logger.info("Starting inactive account identification with threshold: #{INACTIVITY_THRESHOLD}")

    accounts = Account.active
                      .where.not("custom_attributes->>'marked_for_deletion_at' IS NOT NULL")
                      .where('created_at < ?', INACTIVITY_THRESHOLD.ago)

    inactive_account_ids = []

    accounts.find_each do |account|
      next unless account_inactive?(account)

      inactive_account_ids << account.id
      Rails.logger.info("Account #{account.id} (#{account.name}) identified as inactive")
    end

    Rails.logger.info("Found #{inactive_account_ids.length} inactive accounts")
    Account.where(id: inactive_account_ids)
  end

  private

  def account_inactive?(account)
    no_recent_user_activity?(account) && no_recent_conversation_activity?(account)
  end

  def no_recent_user_activity?(account)
    cutoff_date = INACTIVITY_THRESHOLD.ago

    # Check if any user has been active on this account recently
    recent_activity = account.account_users
                             .where('active_at > ?', cutoff_date)
                             .exists?

    !recent_activity
  end

  def no_recent_conversation_activity?(account)
    cutoff_date = INACTIVITY_THRESHOLD.ago

    # Check if there are any recent conversations (created or updated)
    recent_conversations = account.conversations
                                  .where('created_at > ? OR updated_at > ?', cutoff_date, cutoff_date)
                                  .exists?

    !recent_conversations
  end
end