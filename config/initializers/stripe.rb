require 'stripe'

Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY', nil)

# Set API version if specified
Stripe.api_version = ENV['STRIPE_API_VERSION'] if ENV['STRIPE_API_VERSION'].present?

# V2 Billing Configuration
Rails.application.config.stripe_v2 = {
  enabled: ENV['STRIPE_V2_ENABLED'] == 'true',
  usage_reporting_enabled: ENV['STRIPE_V2_USAGE_REPORTING_ENABLED'] != 'false',
  meter_id: ENV.fetch('STRIPE_V2_METER_ID', nil),
  meter_event_name: ENV.fetch('STRIPE_V2_METER_EVENT_NAME', nil),

  # Plan-specific configurations
  plans: {
    free: {
      pricing_plan_id: ENV.fetch('STRIPE_V2_FREE_PLAN_ID', nil),
      monthly_credits: ENV.fetch('STRIPE_V2_FREE_CREDITS', '100').to_i,
      price_per_agent_per_month: ENV.fetch('STRIPE_V2_FREE_PRICE', '0').to_f
    },
    startup: {
      pricing_plan_id: ENV.fetch('STRIPE_V2_STARTUP_PLAN_ID', nil),
      monthly_credits: ENV.fetch('STRIPE_V2_STARTUP_CREDITS', '500').to_i,
      price_per_agent_per_month: ENV.fetch('STRIPE_V2_STARTUP_PRICE', '19').to_f
    },
    business: {
      pricing_plan_id: ENV.fetch('STRIPE_V2_BUSINESS_PLAN_ID', nil),
      monthly_credits: ENV.fetch('STRIPE_V2_BUSINESS_CREDITS', '2000').to_i,
      price_per_agent_per_month: ENV.fetch('STRIPE_V2_BUSINESS_PRICE', '39').to_f
    },
    enterprise: {
      pricing_plan_id: ENV.fetch('STRIPE_V2_ENTERPRISE_PLAN_ID', nil),
      monthly_credits: ENV.fetch('STRIPE_V2_ENTERPRISE_CREDITS', '5000').to_i,
      price_per_agent_per_month: ENV.fetch('STRIPE_V2_ENTERPRISE_PRICE', '99').to_f
    }
  },

  # Topup configuration (same for all plans)
  topup: {
    price_per_credit: ENV.fetch('STRIPE_V2_TOPUP_PRICE_PER_CREDIT', '0.01').to_f,
    available_packs: [100, 500, 1000, 2500, 5000]
  }
}
