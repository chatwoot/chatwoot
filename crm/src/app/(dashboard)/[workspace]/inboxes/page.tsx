import Link from 'next/link'
import { notFound } from 'next/navigation'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Plus, MessageSquare, Mail, Zap, Settings } from 'lucide-react'

const CHANNEL_ICONS = {
  LIVE_CHAT: MessageSquare,
  EMAIL: Mail,
  API: Zap,
}

const CHANNEL_LABELS = {
  LIVE_CHAT: 'Live Chat',
  EMAIL: 'Email',
  API: 'API',
}

export default async function InboxesPage({
  params,
}: {
  params: Promise<{ workspace: string }>
}) {
  const { workspace: slug } = await params
  const session = await auth()

  const account = await db.account.findUnique({
    where: { slug },
    include: {
      members: { where: { userId: session!.user!.id } },
      inboxes: {
        orderBy: { createdAt: 'asc' },
        include: { _count: { select: { conversations: true } } },
      },
    },
  })
  if (!account || !account.members.length) notFound()

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-slate-900">Inboxes</h1>
          <p className="text-sm text-slate-500">{account.inboxes.length} configured</p>
        </div>
        <Button asChild>
          <Link href={`/${slug}/inboxes/new`}>
            <Plus className="mr-2 h-4 w-4" />
            New inbox
          </Link>
        </Button>
      </div>

      {account.inboxes.length === 0 ? (
        <div className="rounded-xl border border-dashed border-slate-200 py-16 text-center">
          <p className="text-sm text-slate-400">No inboxes yet.</p>
          <Button asChild className="mt-4" variant="outline">
            <Link href={`/${slug}/inboxes/new`}>Create your first inbox</Link>
          </Button>
        </div>
      ) : (
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {account.inboxes.map((inbox) => {
            const Icon = CHANNEL_ICONS[inbox.channelType]
            return (
              <div
                key={inbox.id}
                className="flex flex-col rounded-xl border border-slate-200 bg-white p-5"
              >
                <div className="flex items-start justify-between">
                  <div className="flex items-center gap-3">
                    <div
                      className="flex h-9 w-9 items-center justify-center rounded-lg"
                      style={{
                        backgroundColor:
                          inbox.channelType === 'LIVE_CHAT'
                            ? `${inbox.widgetColor}20`
                            : '#f1f5f9',
                      }}
                    >
                      <Icon
                        className="h-4 w-4"
                        style={{
                          color:
                            inbox.channelType === 'LIVE_CHAT' ? inbox.widgetColor : '#64748b',
                        }}
                      />
                    </div>
                    <div>
                      <p className="text-sm font-semibold text-slate-900">{inbox.name}</p>
                      <Badge variant="outline">{CHANNEL_LABELS[inbox.channelType]}</Badge>
                    </div>
                  </div>
                  <Link
                    href={`/${slug}/inboxes/${inbox.id}`}
                    className="text-slate-400 hover:text-slate-700"
                  >
                    <Settings className="h-4 w-4" />
                  </Link>
                </div>

                {inbox.channelType === 'EMAIL' && inbox.email && (
                  <p className="mt-3 truncate text-xs text-slate-500">{inbox.email}</p>
                )}

                <p className="mt-auto pt-3 text-xs text-slate-400">
                  {inbox._count.conversations} conversations
                </p>
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}
