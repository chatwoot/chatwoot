import { NextRequest, NextResponse } from 'next/server'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'
import { stripe } from '@/lib/stripe'

export async function POST(req: NextRequest) {
  const session = await auth()
  if (!session?.user?.id) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const form = await req.formData()
  const workspace = form.get('workspace') as string
  const origin = process.env.NEXTAUTH_URL ?? 'http://localhost:3000'

  const account = await db.account.findUnique({
    where: { slug: workspace },
    include: { members: { where: { userId: session.user.id } } },
  })
  if (!account || !account.members.length) {
    return NextResponse.redirect(`${origin}/${workspace}/settings/billing`, 303)
  }

  // Create Stripe customer if needed
  let customerId = account.stripeCustomerId
  if (!customerId) {
    const customer = await stripe.customers.create({
      email: session.user.email ?? undefined,
      name: account.name,
      metadata: { accountId: account.id, workspace },
    })
    customerId = customer.id
    await db.account.update({ where: { id: account.id }, data: { stripeCustomerId: customerId } })
  }

  const checkoutSession = await stripe.checkout.sessions.create({
    customer: customerId,
    mode: 'subscription',
    line_items: [{ price: process.env.STRIPE_PRO_PRICE_ID!, quantity: 1 }],
    success_url: `${origin}/${workspace}/settings/billing?success=1`,
    cancel_url: `${origin}/${workspace}/settings/billing`,
    metadata: { accountId: account.id },
    allow_promotion_codes: true,
  })

  return NextResponse.redirect(checkoutSession.url!, 303)
}
