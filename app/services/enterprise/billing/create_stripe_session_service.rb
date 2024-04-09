class Enterprise::Billing::CreateStripeSessionService
  def create_stripe_session(customer_id, return_url = ENV.fetch('FRONTEND_URL'))
    # Create Billing Portal Configuration
    configuration = Stripe::BillingPortal::Configuration.create(
      business_profile: {
        headline: 'OneHash, Inc. partners with Stripe for simplified billing'
      },
      features: {
        subscription_update: {
          default_allowed_updates: %w[price promotion_code],
          enabled: true,
          proration_behavior: 'always_invoice',
          products: [
            {
              product: SubscriptionPlan.find_by(plan_name: 'Starter').stripe_product_id,
              prices: [SubscriptionPlan.find_by(plan_name: 'Starter').stripe_price_id]
            },
            {
              product: SubscriptionPlan.find_by(plan_name: 'Plus').stripe_product_id,
              prices: [SubscriptionPlan.find_by(plan_name: 'Plus').stripe_price_id]
            },
            {
              product: SubscriptionPlan.find_by(plan_name: 'Pro').stripe_product_id,
              prices: [SubscriptionPlan.find_by(plan_name: 'Pro').stripe_price_id]
            }
          ]
        },
        customer_update: {
          enabled: true,
          allowed_updates: %w[name email address]
        },
        payment_method_update: {
          enabled: true
        },
        subscription_cancel: {
          'cancellation_reason': {
            'enabled': true,
            'options': %w[
              too_expensive
              missing_features
              switched_service
              unused
              other
            ]
          },
          enabled: true,
          mode: 'at_period_end'
        },
        subscription_pause: {
          'enabled': false
        },
        invoice_history: {
          enabled: true
        }
      }
    )
    Stripe::BillingPortal::Session.create(
      {
        customer: customer_id,
        return_url: return_url,
        configuration: configuration.id
      }
    )
  end
end
