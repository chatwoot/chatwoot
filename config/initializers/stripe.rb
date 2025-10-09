require 'stripe'

Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY', nil)

# Set API version - using V2 preview version for credit management
Stripe.api_version = ENV['STRIPE_API_VERSION'] || '2025-08-27.preview'

# V2 Billing Configuration
Rails.application.config.stripe_v2 = {
  enabled: ENV['STRIPE_V2_ENABLED'] == 'true',
  meter_id: ENV.fetch('STRIPE_V2_METER_ID', nil),
  meter_event_name: ENV.fetch('STRIPE_V2_METER_EVENT_NAME', nil)
}
