import { notFound } from 'next/navigation'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'
import { createWebhook, deleteWebhook, toggleWebhook } from '@/app/actions/webhooks'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Trash2 } from 'lucide-react'

const ALL_EVENTS = [
  { value: 'conversation_created', label: 'Conversation created' },
  { value: 'conversation_updated', label: 'Conversation updated' },
  { value: 'message_created', label: 'Message received' },
]

export default async function WebhooksPage({
  params,
}: {
  params: Promise<{ workspace: string }>
}) {
  const { workspace: slug } = await params
  const session = await auth()

  const account = await db.account.findUnique({
    where: { slug },
    include: { members: { where: { userId: session!.user!.id } } },
  })
  if (!account || !account.members.length) notFound()

  const webhooks = await db.webhookSubscription.findMany({
    where: { accountId: account.id },
    orderBy: { createdAt: 'desc' },
  })

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold text-slate-900">Webhooks</h1>
        <p className="text-sm text-slate-500">
          Receive HTTP POST events when things happen in your workspace
        </p>
      </div>

      {/* New webhook form */}
      <div className="rounded-xl border border-slate-200 bg-white p-5">
        <h2 className="mb-4 text-sm font-semibold text-slate-900">Add webhook</h2>
        <form
          action={async (fd: FormData) => {
            'use server'
            await createWebhook(undefined, fd)
          }}
          className="space-y-4 max-w-lg"
        >
          <input type="hidden" name="workspace" value={slug} />

          <div className="space-y-1.5">
            <Label htmlFor="url">Endpoint URL *</Label>
            <Input id="url" name="url" type="url" placeholder="https://yourapp.com/webhook" required />
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="secret">Secret (optional)</Label>
            <Input
              id="secret"
              name="secret"
              placeholder="Used to sign the request body (HMAC-SHA256)"
            />
            <p className="text-xs text-slate-400">
              If set, each request includes an{' '}
              <code className="rounded bg-slate-100 px-1">X-Webhook-Signature</code> header.
            </p>
          </div>

          <div className="space-y-2">
            <Label>Events *</Label>
            <div className="space-y-1.5">
              {ALL_EVENTS.map((e) => (
                <label key={e.value} className="flex items-center gap-2 text-sm text-slate-700">
                  <input
                    type="checkbox"
                    name="events"
                    value={e.value}
                    className="rounded border-slate-300"
                  />
                  {e.label}
                </label>
              ))}
            </div>
          </div>

          <Button type="submit">Add webhook</Button>
        </form>
      </div>

      {/* Existing webhooks */}
      {webhooks.length > 0 && (
        <div className="rounded-xl border border-slate-200 bg-white">
          <ul className="divide-y divide-slate-100">
            {webhooks.map((wh) => {
              const events = wh.events as string[]
              return (
                <li key={wh.id} className="flex items-center justify-between gap-4 px-4 py-3">
                  <div className="min-w-0">
                    <p className="truncate text-sm font-medium text-slate-900">{wh.url}</p>
                    <p className="text-xs text-slate-400">
                      {events.length ? events.join(', ') : 'No events selected'}
                    </p>
                  </div>
                  <div className="flex shrink-0 items-center gap-2">
                    <form
                      action={async () => {
                        'use server'
                        await toggleWebhook(slug, wh.id, !wh.active)
                      }}
                    >
                      <button
                        type="submit"
                        className={[
                          'relative inline-flex h-5 w-9 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors focus:outline-none',
                          wh.active ? 'bg-indigo-500' : 'bg-slate-200',
                        ].join(' ')}
                      >
                        <span
                          className={[
                            'pointer-events-none inline-block h-4 w-4 rounded-full bg-white shadow ring-0 transition-transform',
                            wh.active ? 'translate-x-4' : 'translate-x-0',
                          ].join(' ')}
                        />
                      </button>
                    </form>
                    <form
                      action={async () => {
                        'use server'
                        await deleteWebhook(slug, wh.id)
                      }}
                    >
                      <Button variant="ghost" size="icon" type="submit">
                        <Trash2 className="h-3.5 w-3.5 text-red-400" />
                      </Button>
                    </form>
                  </div>
                </li>
              )
            })}
          </ul>
        </div>
      )}
    </div>
  )
}
