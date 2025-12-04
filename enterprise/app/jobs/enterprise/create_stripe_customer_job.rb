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
    return if account.custom_attributes['is_creating_customer'].blank?

    account.update(custom_attributes: account.custom_attributes.except('is_creating_customer'))
  rescue StandardError => e
    Rails.logger.error("Failed to clear is_creating_customer flag: #{e.message}")
  end
end
