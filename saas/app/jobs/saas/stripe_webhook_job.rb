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
    when 'customer.subscription.trial_will_end'
      handle_trial_will_end(event)
    when 'invoice.payment_succeeded'
      handle_payment_succeeded(event)
    when 'invoice.payment_failed'
      handle_payment_failed(event)
    end
  end

  def handle_trial_will_end(event)
    stripe_sub = event.data.object
    subscription = find_subscription_by_stripe(stripe_sub)
    return unless subscription

    Saas::BillingMailer.trial_expiring(subscription.account).deliver_later
  end

  def handle_payment_succeeded(event)
    invoice = event.data.object
    subscription = find_subscription_by_customer(invoice.customer)
    return unless subscription
    return unless subscription.past_due? || subscription.unpaid?

    # Re-activate subscription after successful payment
    subscription.update!(status: :active)
    Rails.logger.info("[Stripe] Payment succeeded — reactivated account #{subscription.account_id}")
  end

  def handle_payment_failed(event)
    invoice = event.data.object
    subscription = find_subscription_by_customer(invoice.customer)
    return unless subscription

    attempt_count = invoice.attempt_count.to_i
    if attempt_count >= 3
      # After 3 failed attempts, mark unpaid and suspend features
      subscription.update!(status: :unpaid)
      Rails.logger.warn("[Stripe] 3+ payment failures — suspended account #{subscription.account_id}")
    else
      subscription.update!(status: :past_due)
    end

    Saas::BillingMailer.payment_failed(subscription.account, attempt_count).deliver_later
  end

  def find_subscription_by_stripe(stripe_sub)
    account_id = stripe_sub.metadata['account_id']&.to_i
    return Account.find_by(id: account_id)&.saas_subscription if account_id

    Saas::Subscription.find_by(stripe_subscription_id: stripe_sub.id)
  end

  def find_subscription_by_customer(customer_id)
    Saas::Subscription.find_by(stripe_customer_id: customer_id)
  end
end
