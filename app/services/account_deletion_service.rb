class AccountDeletionService
  attr_reader :account

  def initialize(account:)
    @account = account
  end

  def perform
    Rails.logger.info("Deleting account #{account.id} - #{account.name} that was marked for deletion")

    # Use the existing DeleteObjectJob to delete the account
    DeleteObjectJob.perform_later(account)
  end
end
