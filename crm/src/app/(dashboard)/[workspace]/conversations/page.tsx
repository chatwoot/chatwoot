import Link from 'next/link'
import { notFound } from 'next/navigation'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Avatar } from '@/components/ui/avatar'
import { Plus } from 'lucide-react'
import { cn } from '@/lib/utils'
import type { ConversationStatus } from '@/generated/prisma/client'

const STATUS_TABS: { label: string; value: ConversationStatus | 'ALL' }[] = [
  { label: 'All', value: 'ALL' },
  { label: 'Open', value: 'OPEN' },
  { label: 'Pending', value: 'PENDING' },
  { label: 'Resolved', value: 'RESOLVED' },
  { label: 'Snoozed', value: 'SNOOZED' },
]

const STATUS_BADGE: Record<ConversationStatus, 'success' | 'warning' | 'default' | 'outline'> = {
  OPEN: 'success',
  PENDING: 'warning',
  RESOLVED: 'default',
  SNOOZED: 'outline',
}

const PER_PAGE = 30

export default async function ConversationsPage({
  params,
  searchParams,
}: {
  params: Promise<{ workspace: string }>
  searchParams: Promise<{ status?: string; inbox?: string; page?: string }>
}) {
  const { workspace: slug } = await params
  const { status = 'OPEN', inbox: inboxFilter, page = '1' } = await searchParams

  const session = await auth()
  const account = await db.account.findUnique({
    where: { slug },
    include: {
      members: { where: { userId: session!.user!.id } },
      inboxes: true,
    },
  })
  if (!account || !account.members.length) notFound()

  const pageNum = Math.max(1, parseInt(page))
  const skip = (pageNum - 1) * PER_PAGE

  const where = {
    accountId: account.id,
    ...(status !== 'ALL' && { status: status as ConversationStatus }),
    ...(inboxFilter && { inboxId: inboxFilter }),
  }

  const [conversations, total] = await Promise.all([
    db.conversation.findMany({
      where,
      orderBy: { updatedAt: 'desc' },
      skip,
      take: PER_PAGE,
      include: {
        contact: true,
        inbox: true,
        assignee: true,
        messages: { orderBy: { createdAt: 'desc' }, take: 1 },
      },
    }),
    db.conversation.count({ where }),
  ])

  const totalPages = Math.ceil(total / PER_PAGE)

  return (
    <div className="flex h-full flex-col space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold text-slate-900">Conversations</h1>
        <Button asChild size="sm">
          <Link href={`/${slug}/conversations/new`}>
            <Plus className="mr-1.5 h-4 w-4" />
            New
          </Link>
        </Button>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-center gap-2">
        <div className="flex rounded-lg border border-slate-200 bg-white p-0.5">
          {STATUS_TABS.map((tab) => (
            <Link
              key={tab.value}
              href={`?status=${tab.value}${inboxFilter ? `&inbox=${inboxFilter}` : ''}`}
              className={cn(
                'rounded-md px-3 py-1.5 text-xs font-medium transition-colors',
                status === tab.value
                  ? 'bg-slate-900 text-white'
                  : 'text-slate-500 hover:text-slate-900',
              )}
            >
              {tab.label}
            </Link>
          ))}
        </div>

        {account.inboxes.length > 0 && (
          <select
            className="h-8 rounded-lg border border-slate-200 bg-white px-3 text-xs text-slate-600 focus:outline-none focus:ring-2 focus:ring-slate-900"
            defaultValue={inboxFilter ?? ''}
            onChange={(e) => {
              const url = new URL(window.location.href)
              if (e.target.value) url.searchParams.set('inbox', e.target.value)
              else url.searchParams.delete('inbox')
              window.location.href = url.toString()
            }}
          >
            <option value="">All inboxes</option>
            {account.inboxes.map((inbox) => (
              <option key={inbox.id} value={inbox.id}>
                {inbox.name}
              </option>
            ))}
          </select>
        )}
      </div>

      {/* List */}
      <div className="flex-1 rounded-xl border border-slate-200 bg-white overflow-hidden">
        {conversations.length === 0 ? (
          <div className="py-16 text-center text-sm text-slate-400">
            No conversations found.
          </div>
        ) : (
          <ul className="divide-y divide-slate-100">
            {conversations.map((conv) => {
              const lastMsg = conv.messages[0]
              const name = conv.contact?.name ?? 'Unknown visitor'
              return (
                <li key={conv.id}>
                  <Link
                    href={`/${slug}/conversations/${conv.id}`}
                    className="flex items-start gap-3 px-4 py-3 hover:bg-slate-50 transition-colors"
                  >
                    <Avatar name={name} className="mt-0.5 shrink-0" />
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center justify-between gap-2">
                        <span className="truncate text-sm font-medium text-slate-900">
                          {name}
                        </span>
                        <div className="flex shrink-0 items-center gap-2">
                          <Badge variant={STATUS_BADGE[conv.status]} className="hidden sm:inline-flex">
                            {conv.status}
                          </Badge>
                          <span className="text-xs text-slate-400">
                            {new Date(conv.updatedAt).toLocaleDateString()}
                          </span>
                        </div>
                      </div>
                      <div className="flex items-center gap-2">
                        <span className="text-xs text-slate-400">{conv.inbox.name}</span>
                        {conv.assignee && (
                          <span className="text-xs text-slate-400">· {conv.assignee.name}</span>
                        )}
                      </div>
                      {lastMsg && (
                        <p className="mt-0.5 truncate text-xs text-slate-500">
                          {lastMsg.authorType === 'agent' ? 'You: ' : ''}
                          {lastMsg.content}
                        </p>
                      )}
                    </div>
                  </Link>
                </li>
              )
            })}
          </ul>
        )}
      </div>

      {totalPages > 1 && (
        <div className="flex items-center justify-between text-sm">
          <span className="text-slate-500">Page {pageNum} of {totalPages}</span>
          <div className="flex gap-2">
            {pageNum > 1 && (
              <Button variant="outline" size="sm" asChild>
                <Link href={`?status=${status}&page=${pageNum - 1}`}>Previous</Link>
              </Button>
            )}
            {pageNum < totalPages && (
              <Button variant="outline" size="sm" asChild>
                <Link href={`?status=${status}&page=${pageNum + 1}`}>Next</Link>
              </Button>
            )}
          </div>
        </div>
      )}
    </div>
  )
}
