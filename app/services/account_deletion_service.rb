class AccountDeletionService
  attr_reader :account, :soft_deleted_users

  def initialize(account:)
    @account = account
    @soft_deleted_users = []
  end

  def perform
    Rails.logger.info("Deleting account #{account.id} - #{account.name} that was marked for deletion")

    soft_delete_orphaned_users
    send_compliance_notification
    DeleteObjectJob.perform_later(account)
  end

  private

  def send_compliance_notification
    AdministratorNotifications::AccountComplianceMailer.with(
      account: account,
      soft_deleted_users: soft_deleted_users
    ).account_deleted(account).deliver_later
  end

  def soft_delete_orphaned_users
    account.users.each do |user|
      # Skip if user belongs to other accounts
      next if user.accounts.count > 1

      # Soft delete user by appending -deleted.com to email
      original_email = user.email
      user.email = "#{original_email}-deleted.com"
      user.skip_reconfirmation!
      user.save!

      soft_deleted_users << {
        id: user.id,
        original_email: original_email
      }

      Rails.logger.info("Soft deleted orphaned user #{original_email}, new email: #{user.email}")
    end
  end
end
