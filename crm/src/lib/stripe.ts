import Stripe from 'stripe'

const globalForStripe = globalThis as unknown as { stripe: Stripe }

export const stripe =
  globalForStripe.stripe ??
  new Stripe(process.env.STRIPE_SECRET_KEY ?? 'sk_test_placeholder', {
    apiVersion: '2025-03-31.basil',
  })

if (process.env.NODE_ENV !== 'production') globalForStripe.stripe = stripe
