require 'stripe'

Stripe.api_key = ENV.fetch('STRIPE_PRIVATE_KEY', nil)
