class Enterprise::CancelCloudSubscriptionsJob < ApplicationJob
  queue_as :default

  # The account is deleted 7 days after it is marked, so a Stripe outage has time to recover.
  # Retries are safe: the service skips subscriptions that already have a cancellation scheduled.
  retry_on Stripe::StripeError, wait: :polynomially_longer, attempts: 10

  def perform(account)
    Enterprise::Billing::CancelCloudSubscriptionsService.new(account: account).perform
  end
end
