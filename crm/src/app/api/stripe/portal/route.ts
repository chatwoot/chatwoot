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
  const returnUrl = `${origin}/${workspace}/settings/billing`

  const account = await db.account.findUnique({
    where: { slug: workspace },
    include: { members: { where: { userId: session.user.id } } },
  })
  if (!account || !account.members.length || !account.stripeCustomerId) {
    return NextResponse.redirect(returnUrl, 303)
  }

  const portalSession = await stripe.billingPortal.sessions.create({
    customer: account.stripeCustomerId,
    return_url: returnUrl,
  })

  return NextResponse.redirect(portalSession.url, 303)
}
