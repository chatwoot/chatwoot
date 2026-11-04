class Enterprise::CancelCloudSubscriptionsJob < ApplicationJob
  queue_as :default

  # The account is deleted 7 days after it is marked, so a Stripe outage has time to recover.
  # Retries are safe: the service skips subscriptions that already have a cancellation scheduled.
  retry_on Stripe::StripeError, wait: :polynomially_longer, attempts: 10

  def perform(account)
    # A retry can land after the admin cancelled the deletion; don't cancel a retained account's plan.
    return if account.custom_attributes['marked_for_deletion_at'].blank?

    Enterprise::Billing::CancelCloudSubscriptionsService.new(account: account).perform
  end
end
