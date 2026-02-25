class AccountDeletionService
  SOFT_DELETE_EMAIL_DOMAIN = '@chatwoot-deleted.invalid'.freeze

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
      # Skip users who are still associated with another account.
      next if user.account_users.where.not(account_id: account.id).exists?

      original_email = user.email
      user.email = soft_deleted_email_for(user)
      user.skip_reconfirmation!
      user.save!

      user_info = {
        id: user.id.to_s,
        original_email: original_email
      }

      soft_deleted_users << user_info

      Rails.logger.info("Soft deleted user #{user.id} with email #{original_email}")
    end
  end

  def soft_deleted_email_for(user)
    "#{user.id}#{SOFT_DELETE_EMAIL_DOMAIN}"
  end
end
