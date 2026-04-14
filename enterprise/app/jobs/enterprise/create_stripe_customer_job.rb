class Enterprise::CreateStripeCustomerJob < ApplicationJob
  queue_as :default

  def perform(account)
    Enterprise::Billing::CreateStripeCustomerService.new(account: account).perform
  ensure
    # Always clear the is_creating_customer flag, even if the job fails
    # This prevents users from getting stuck on the billing page
    clear_creating_flag(account)
  end

  private

  def clear_creating_flag(account)
    Account.where(id: account.id).update_all(
      "custom_attributes = custom_attributes - 'is_creating_customer'"
    )
  rescue StandardError => e
    Rails.logger.error("Failed to clear is_creating_customer flag for account=#{account.id}: #{e.full_message}")
  end
end
