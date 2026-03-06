# Custom webhook handlers for billing events.
# Pay gem handles syncing Stripe objects to Pay models automatically.
# These handlers add AlooChat-specific behavior on top:
#   - Plan feature sync (Billable#sync_plan_features!)
#   - Auto-suspend on unpaid status
#   - Auto-reactivate on charge success
#   - Post-checkout feature sync
#
# Handler logic lives in BillingWebhookHandlers for testability.
# Each lambda finds the Pay model from the Stripe event, then delegates.

ActiveSupport.on_load(:pay) do
  # ── Plan sync: subscription created/updated/deleted ────────────
  plan_sync = lambda { |event|
    stripe_sub_id = event.data.object.id
    pay_sub = Pay::Subscription.find_by(processor_id: stripe_sub_id)
    BillingWebhookHandlers.handle_plan_sync(pay_sub)
  }

  Pay::Webhooks.delegator.subscribe 'stripe.customer.subscription.created', plan_sync
  Pay::Webhooks.delegator.subscribe 'stripe.customer.subscription.deleted', plan_sync

  # ── Subscription updated: plan sync + auto-suspend on unpaid ───
  Pay::Webhooks.delegator.subscribe 'stripe.customer.subscription.updated', lambda { |event|
    stripe_sub_id = event.data.object.id
    pay_sub = Pay::Subscription.find_by(processor_id: stripe_sub_id)
    BillingWebhookHandlers.handle_subscription_updated(pay_sub)
  }

  # ── Auto-reactivate: charge succeeded on suspended account ─────
  Pay::Webhooks.delegator.subscribe 'stripe.charge.succeeded', lambda { |event|
    stripe_customer_id = event.data.object.customer
    pay_customer = Pay::Customer.find_by(processor: :stripe, processor_id: stripe_customer_id)
    BillingWebhookHandlers.handle_charge_succeeded(pay_customer)
  }

  # ── Overage billing: add AI overage line items to upcoming invoices
  Pay::Webhooks.delegator.subscribe 'stripe.invoice.created', lambda { |event|
    stripe_customer_id = event.data.object.customer
    pay_customer = Pay::Customer.find_by(processor: :stripe, processor_id: stripe_customer_id)
    BillingWebhookHandlers.handle_invoice_created(pay_customer)
  }

  # ── Post-checkout: sync features after first successful checkout
  Pay::Webhooks.delegator.subscribe 'stripe.checkout.session.completed', lambda { |event|
    stripe_customer_id = event.data.object.customer
    pay_customer = Pay::Customer.find_by(processor: :stripe, processor_id: stripe_customer_id)
    BillingWebhookHandlers.handle_checkout_completed(pay_customer)
  }
end
