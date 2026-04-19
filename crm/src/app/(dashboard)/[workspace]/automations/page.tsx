import { notFound } from 'next/navigation'
import Link from 'next/link'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'
import { deleteAutomation, toggleAutomation } from '@/app/actions/automations'
import { Button } from '@/components/ui/button'
import { Plus, Pencil, Trash2 } from 'lucide-react'

export default async function AutomationsPage({
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

  const automations = await db.automation.findMany({
    where: { accountId: account.id },
    orderBy: { createdAt: 'desc' },
  })

  const EVENT_LABELS: Record<string, string> = {
    conversation_created: 'Conversation created',
    conversation_updated: 'Conversation updated',
    message_created: 'Message received',
  }

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-slate-900">Automations</h1>
          <p className="text-sm text-slate-500">Rules that run automatically on events</p>
        </div>
        <Button asChild>
          <Link href={`/${slug}/automations/new`}>
            <Plus className="mr-1.5 h-4 w-4" />
            New automation
          </Link>
        </Button>
      </div>

      {automations.length === 0 ? (
        <div className="rounded-xl border border-dashed border-slate-200 bg-white p-10 text-center">
          <p className="text-sm text-slate-500">No automations yet.</p>
          <Button asChild className="mt-4" variant="outline">
            <Link href={`/${slug}/automations/new`}>Create your first automation</Link>
          </Button>
        </div>
      ) : (
        <ul className="space-y-2">
          {automations.map((a) => (
            <li
              key={a.id}
              className="flex items-center justify-between gap-4 rounded-xl border border-slate-200 bg-white px-4 py-3"
            >
              <div className="min-w-0">
                <p className="truncate text-sm font-medium text-slate-900">{a.name}</p>
                <p className="text-xs text-slate-400">
                  {EVENT_LABELS[a.event] ?? a.event} ·{' '}
                  {(a.conditions as unknown[]).length} condition
                  {(a.conditions as unknown[]).length !== 1 ? 's' : ''} ·{' '}
                  {(a.actions as unknown[]).length} action
                  {(a.actions as unknown[]).length !== 1 ? 's' : ''}
                </p>
              </div>

              <div className="flex shrink-0 items-center gap-2">
                <form
                  action={async () => {
                    'use server'
                    await toggleAutomation(slug, a.id, !a.active)
                  }}
                >
                  <button
                    type="submit"
                    className={[
                      'relative inline-flex h-5 w-9 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors focus:outline-none',
                      a.active ? 'bg-indigo-500' : 'bg-slate-200',
                    ].join(' ')}
                  >
                    <span
                      className={[
                        'pointer-events-none inline-block h-4 w-4 rounded-full bg-white shadow ring-0 transition-transform',
                        a.active ? 'translate-x-4' : 'translate-x-0',
                      ].join(' ')}
                    />
                  </button>
                </form>

                <Button variant="ghost" size="icon" asChild>
                  <Link href={`/${slug}/automations/${a.id}`}>
                    <Pencil className="h-3.5 w-3.5" />
                  </Link>
                </Button>

                <form
                  action={async () => {
                    'use server'
                    await deleteAutomation(slug, a.id)
                  }}
                >
                  <Button variant="ghost" size="icon" type="submit">
                    <Trash2 className="h-3.5 w-3.5 text-red-400" />
                  </Button>
                </form>
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}
