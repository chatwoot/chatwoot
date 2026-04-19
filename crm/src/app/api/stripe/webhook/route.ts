import { NextRequest, NextResponse } from 'next/server'
import type Stripe from 'stripe'
import { stripe } from '@/lib/stripe'
import { db } from '@/lib/db'

export async function POST(req: NextRequest) {
  const body = await req.text()
  const sig = req.headers.get('stripe-signature')

  if (!sig || !process.env.STRIPE_WEBHOOK_SECRET) {
    return NextResponse.json({ error: 'Missing signature' }, { status: 400 })
  }

  let event: Stripe.Event
  try {
    event = stripe.webhooks.constructEvent(body, sig, process.env.STRIPE_WEBHOOK_SECRET)
  } catch {
    return NextResponse.json({ error: 'Invalid signature' }, { status: 400 })
  }

  switch (event.type) {
    case 'checkout.session.completed': {
      const session = event.data.object as Stripe.Checkout.Session
      if (session.mode !== 'subscription') break
      const accountId = session.metadata?.accountId
      if (!accountId) break
      await db.account.update({
        where: { id: accountId },
        data: {
          plan: 'pro',
          stripeCustomerId: session.customer as string,
          stripeSubscriptionId: session.subscription as string,
          subscriptionStatus: 'active',
        },
      })
      break
    }

    case 'customer.subscription.updated': {
      const sub = event.data.object as Stripe.Subscription
      await db.account.updateMany({
        where: { stripeSubscriptionId: sub.id },
        data: {
          subscriptionStatus: sub.status,
          stripePriceId: sub.items.data[0]?.price.id ?? null,
        },
      })
      break
    }

    case 'customer.subscription.deleted': {
      const sub = event.data.object as Stripe.Subscription
      await db.account.updateMany({
        where: { stripeSubscriptionId: sub.id },
        data: {
          plan: 'free',
          subscriptionStatus: 'canceled',
          stripeSubscriptionId: null,
          stripePriceId: null,
        },
      })
      break
    }

    case 'invoice.payment_failed': {
      const invoice = event.data.object as Stripe.Invoice
      const subId =
        typeof invoice.subscription === 'string'
          ? invoice.subscription
          : (invoice.subscription as Stripe.Subscription | null)?.id
      if (subId) {
        await db.account.updateMany({
          where: { stripeSubscriptionId: subId },
          data: { subscriptionStatus: 'past_due' },
        })
      }
      break
    }
  }

  return NextResponse.json({ received: true })
}
