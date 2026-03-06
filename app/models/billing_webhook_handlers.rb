# Webhook handler methods for billing events.
# Each method is called from config/initializers/pay_webhooks.rb
# and takes a Pay model (subscription, customer, or charge) as input.
#
# Keeps handler logic testable without requiring Stripe API mocks.
# Each method calls one or two Billable methods on the account.
#
module BillingWebhookHandlers
  module_function

  # Called on subscription.created, subscription.updated, subscription.deleted
  # Re-syncs plan features from the current active plan.
  def handle_plan_sync(pay_subscription)
    return unless pay_subscription

    account = pay_subscription.customer&.owner
    return unless account.is_a?(Account)

    account.sync_plan_features!
  end

  # Called on subscription.updated — checks for unpaid status to auto-suspend.
  # Also syncs plan features for any subscription update.
  def handle_subscription_updated(pay_subscription)
    return unless pay_subscription

    account = pay_subscription.customer&.owner
    return unless account.is_a?(Account)

    account.suspend_for_nonpayment! if pay_subscription.status == 'unpaid'

    account.sync_plan_features!
  end

  # Called on charge.succeeded — reactivates suspended accounts.
  def handle_charge_succeeded(pay_customer)
    return unless pay_customer

    account = pay_customer.owner
    return unless account.is_a?(Account) && account.suspended?

    account.reactivate_after_payment!
  end

  # Called on invoice.created — appends overage line items before Stripe finalizes.
  # KWD is 3-decimal: 0.010 KD = 10 fils = amount 10 in Stripe API.
  def handle_invoice_created(pay_customer)
    account = pay_customer&.owner
    return unless account.is_a?(Account)

    usage = account.current_usage
    return unless usage.overage_count.positive?

    amount = usage.overage_count * 10

    ::Stripe::InvoiceItem.create(
      customer: pay_customer.processor_id,
      amount: amount,
      currency: 'kwd',
      description: "AI response overage: #{usage.overage_count} responses \u00d7 0.010 KD"
    )
  end

  # Called on checkout.session.completed — syncs features after first checkout.
  # Clears trial credits so the account transitions to paid plan limits.
  def handle_checkout_completed(pay_customer)
    return unless pay_customer

    account = pay_customer.owner
    return unless account.is_a?(Account)

    account.clear_trial_credits!
    account.sync_plan_features!
  end
end
