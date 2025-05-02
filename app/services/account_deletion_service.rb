class AccountDeletionService
  attr_reader :account

  def initialize(account:)
    @account = account
  end

  def perform
    Rails.logger.info("Deleting account #{account.id} - #{account.name} that was marked for deletion")

    # Send compliance notification to instance admin
    send_compliance_notification

    # Use the existing DeleteObjectJob to delete the account
    DeleteObjectJob.perform_later(account)
  end

  private

  def send_compliance_notification
    AdministratorNotifications::AccountComplianceMailer.with(account: account).account_deleted(account).deliver_later
  end
end
