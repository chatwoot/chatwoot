# frozen_string_literal: true

# Background job for processing Stripe webhook events asynchronously.
# Best practice: return 200 to Stripe immediately, then process the event.
# Reference: https://docs.stripe.com/webhooks#best-practices
class Saas::StripeWebhookJob < ApplicationJob
  queue_as :default

  retry_on Stripe::APIConnectionError, wait: :polynomially_longer, attempts: 5
  retry_on Stripe::RateLimitError, wait: 30.seconds, attempts: 3
  discard_on JSON::ParserError

  def perform(event_json)
    event = Stripe::Event.construct_from(JSON.parse(event_json, symbolize_names: true))

    # Idempotency: skip events we've already processed
    cache_key = "stripe_webhook:#{event.id}"
    return if Rails.cache.read(cache_key)

    handle_event(event)

    # Mark event as processed (expire after 3 days to match Stripe's retry window)
    Rails.cache.write(cache_key, true, expires_in: 3.days)
  rescue StandardError => e
    Rails.logger.error("[Saas::StripeWebhookJob] Failed to process event #{event&.type}: #{e.message}")
    ChatwootExceptionTracker.new(e).capture_exception
  end

  private

  def handle_event(event)
    case event.type
    when 'checkout.session.completed'
      Saas::StripeService.handle_checkout_completed(event)
    when 'customer.subscription.created',
         'customer.subscription.updated',
         'customer.subscription.deleted'
      Saas::StripeService.handle_subscription_event(event)
    when 'invoice.payment_failed'
      handle_payment_failed(event)
    end
  end

  def handle_payment_failed(event)
    invoice = event.data.object
    customer_id = invoice.customer

    subscription = Saas::Subscription.find_by(stripe_customer_id: customer_id)
    return unless subscription

    subscription.update!(status: :past_due)
  end
end
