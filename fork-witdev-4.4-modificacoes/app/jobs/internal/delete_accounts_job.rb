class Internal::DeleteAccountsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    delete_expired_accounts
  end

  private

  def delete_expired_accounts
    accounts_pending_deletion.each do |account|
      AccountDeletionService.new(account: account).perform
    end
  end

  def accounts_pending_deletion
    Account.where("custom_attributes->>'marked_for_deletion_at' IS NOT NULL")
           .select { |account| deletion_period_expired?(account) }
  end

  def deletion_period_expired?(account)
    deletion_time = account.custom_attributes['marked_for_deletion_at']
    return false if deletion_time.blank?

    DateTime.parse(deletion_time) <= Time.current
  end
end
