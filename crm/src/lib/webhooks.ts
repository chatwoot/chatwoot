import { createHmac } from 'crypto'
import { db } from '@/lib/db'

export async function fireWebhooks(
  accountId: string,
  event: string,
  payload: Record<string, unknown>,
) {
  const subs = await db.webhookSubscription.findMany({
    where: { accountId, active: true },
  })

  const matching = subs.filter((s) => {
    const events = s.events as string[]
    return events.includes(event) || events.includes('*')
  })

  if (!matching.length) return

  const body = JSON.stringify({ event, ...payload, timestamp: new Date().toISOString() })

  await Promise.allSettled(
    matching.map(async (sub) => {
      const headers: Record<string, string> = { 'Content-Type': 'application/json' }
      if (sub.secret) {
        headers['X-Webhook-Signature'] = createHmac('sha256', sub.secret)
          .update(body)
          .digest('hex')
      }
      await fetch(sub.url, { method: 'POST', headers, body })
    }),
  )
}
