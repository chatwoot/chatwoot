import { notFound } from 'next/navigation'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'
import { PLANS, getPlan, isPro } from '@/lib/plans'
import { Button } from '@/components/ui/button'
import { CheckCircle, CreditCard, Zap } from 'lucide-react'

const STATUS_LABELS: Record<string, { label: string; cls: string }> = {
  active: { label: 'Active', cls: 'bg-green-50 text-green-700' },
  trialing: { label: 'Trial', cls: 'bg-blue-50 text-blue-700' },
  past_due: { label: 'Past due', cls: 'bg-yellow-50 text-yellow-700' },
  canceled: { label: 'Canceled', cls: 'bg-slate-100 text-slate-500' },
  incomplete: { label: 'Incomplete', cls: 'bg-orange-50 text-orange-700' },
}

export default async function BillingPage({
  params,
  searchParams,
}: {
  params: Promise<{ workspace: string }>
  searchParams: Promise<{ success?: string }>
}) {
  const { workspace: slug } = await params
  const { success } = await searchParams
  const session = await auth()

  const account = await db.account.findUnique({
    where: { slug },
    include: { members: { where: { userId: session!.user!.id } } },
  })
  if (!account || !account.members.length) notFound()

  const planId = getPlan(account.plan)
  const plan = PLANS[planId]
  const pro = isPro(account.plan)
  const status = account.subscriptionStatus
    ? STATUS_LABELS[account.subscriptionStatus]
    : undefined

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold text-slate-900">Billing</h1>
        <p className="text-sm text-slate-500">Manage your subscription and plan</p>
      </div>

      {success && (
        <div className="flex items-center gap-2 rounded-xl bg-green-50 px-4 py-3 text-sm text-green-700">
          <CheckCircle className="h-4 w-4 shrink-0" />
          Subscription activated — you&apos;re now on the Pro plan!
        </div>
      )}

      {/* Current plan card */}
      <div className="rounded-xl border border-slate-200 bg-white p-5">
        <div className="flex items-start justify-between gap-4">
          <div>
            <div className="flex items-center gap-2">
              <h2 className="text-sm font-semibold text-slate-900">Current plan</h2>
              <span
                className={[
                  'rounded-full px-2 py-0.5 text-xs font-medium',
                  pro ? 'bg-indigo-50 text-indigo-700' : 'bg-slate-100 text-slate-600',
                ].join(' ')}
              >
                {plan.name}
              </span>
              {status && (
                <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${status.cls}`}>
                  {status.label}
                </span>
              )}
            </div>
            <p className="mt-1 text-sm text-slate-500">{plan.description}</p>
          </div>

          {pro ? (
            <form method="POST" action="/api/stripe/portal">
              <input type="hidden" name="workspace" value={slug} />
              <Button variant="outline" size="sm" type="submit">
                <CreditCard className="mr-1.5 h-3.5 w-3.5" />
                Manage billing
              </Button>
            </form>
          ) : (
            <form method="POST" action="/api/stripe/checkout">
              <input type="hidden" name="workspace" value={slug} />
              <Button size="sm" type="submit">
                <Zap className="mr-1.5 h-3.5 w-3.5" />
                Upgrade to Pro
              </Button>
            </form>
          )}
        </div>
      </div>

      {/* Plan comparison */}
      <div className="grid gap-4 sm:grid-cols-2">
        {(['free', 'pro'] as const).map((id) => {
          const p = PLANS[id]
          const isCurrent = planId === id
          return (
            <div
              key={id}
              className={[
                'rounded-xl border bg-white p-5',
                isCurrent ? 'border-indigo-300 ring-1 ring-indigo-200' : 'border-slate-200',
              ].join(' ')}
            >
              <div className="mb-1 flex items-center justify-between">
                <h3 className="text-sm font-semibold text-slate-900">{p.name}</h3>
                {isCurrent && (
                  <span className="rounded-full bg-indigo-50 px-2 py-0.5 text-xs font-medium text-indigo-700">
                    Current
                  </span>
                )}
              </div>
              <p className="mb-4 text-2xl font-bold text-slate-900">
                {p.price === 0 ? 'Free' : `$${p.price}`}
                {p.price > 0 && (
                  <span className="text-sm font-normal text-slate-400"> / month</span>
                )}
              </p>
              <ul className="space-y-2">
                {p.features.map((f) => (
                  <li key={f} className="flex items-start gap-2 text-sm text-slate-600">
                    <CheckCircle className="mt-0.5 h-4 w-4 shrink-0 text-green-500" />
                    {f}
                  </li>
                ))}
              </ul>
              {!isCurrent && id === 'pro' && (
                <form method="POST" action="/api/stripe/checkout" className="mt-5">
                  <input type="hidden" name="workspace" value={slug} />
                  <Button type="submit" className="w-full">
                    <Zap className="mr-1.5 h-4 w-4" />
                    Upgrade to Pro
                  </Button>
                </form>
              )}
            </div>
          )
        })}
      </div>

      {/* Env var setup note */}
      {!process.env.STRIPE_PRO_PRICE_ID && (
        <div className="rounded-xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-800">
          <strong>Setup required:</strong> Set{' '}
          <code className="rounded bg-amber-100 px-1">STRIPE_SECRET_KEY</code>,{' '}
          <code className="rounded bg-amber-100 px-1">STRIPE_PRO_PRICE_ID</code>, and{' '}
          <code className="rounded bg-amber-100 px-1">STRIPE_WEBHOOK_SECRET</code> in your
          environment to enable payments.
        </div>
      )}
    </div>
  )
}
