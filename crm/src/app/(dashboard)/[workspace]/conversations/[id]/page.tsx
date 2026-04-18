import { notFound } from 'next/navigation'
import Link from 'next/link'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'
import { updateConversationStatus, assignConversation } from '@/app/actions/conversations'
import { MessageThread } from '@/components/conversations/message-thread'
import { ReplyBox } from '@/components/conversations/reply-box'
import { LabelPicker } from '@/components/conversations/label-picker'
import { Badge } from '@/components/ui/badge'
import { Avatar } from '@/components/ui/avatar'
import { Button } from '@/components/ui/button'
import { ArrowLeft, CheckCircle, RefreshCw, User, Mail } from 'lucide-react'
import type { ConversationStatus } from '@/generated/prisma/client'

const STATUS_BADGE: Record<ConversationStatus, 'success' | 'warning' | 'default' | 'outline'> = {
  OPEN: 'success',
  PENDING: 'warning',
  RESOLVED: 'default',
  SNOOZED: 'outline',
}

export default async function ConversationPage({
  params,
}: {
  params: Promise<{ workspace: string; id: string }>
}) {
  const { workspace: slug, id } = await params
  const session = await auth()

  const account = await db.account.findUnique({
    where: { slug },
    include: {
      members: {
        where: { userId: session!.user!.id },
        include: { user: true },
      },
    },
  })
  if (!account || !account.members.length) notFound()

  const conversation = await db.conversation.findFirst({
    where: { id, accountId: account.id },
    include: {
      contact: true,
      inbox: true,
      assignee: true,
      messages: { orderBy: { createdAt: 'asc' } },
      labels: { include: { label: true } },
    },
  })
  if (!conversation) notFound()

  const allLabels = await db.label.findMany({
    where: { accountId: account.id },
    orderBy: { title: 'asc' },
  })

  const agents = await db.accountMember.findMany({
    where: { accountId: account.id },
    include: { user: true },
  })

  const isResolved = conversation.status === 'RESOLVED'
  const contactName = conversation.contact?.name ?? 'Unknown visitor'

  return (
    <div className="flex h-full flex-col overflow-hidden">
      {/* Header */}
      <div className="flex items-center justify-between border-b border-slate-200 bg-white px-4 py-3">
        <div className="flex items-center gap-3">
          <Button variant="ghost" size="icon" asChild>
            <Link href={`/${slug}/conversations`}>
              <ArrowLeft className="h-4 w-4" />
            </Link>
          </Button>
          {conversation.inbox.channelType === 'EMAIL' ? (
            <Mail className="h-5 w-5 text-slate-400" />
          ) : (
            <Avatar name={contactName} />
          )}
          <div>
            <div className="flex items-center gap-2 flex-wrap">
              <span className="text-sm font-semibold text-slate-900">
                {conversation.subject ?? contactName}
              </span>
              <Badge variant={STATUS_BADGE[conversation.status]}>{conversation.status}</Badge>
            </div>
            <span className="text-xs text-slate-400">
              {conversation.inbox.name}
              {conversation.fromEmail && ` · ${conversation.fromEmail}`}
            </span>
          </div>
        </div>

        <div className="flex items-center gap-2">
          {/* Assign agent */}
          <form
            action={async (fd: FormData) => {
              'use server'
              const agentId = fd.get('agentId') as string
              await assignConversation(slug, id, agentId || null)
            }}
            className="flex items-center gap-1.5"
          >
            <User className="h-4 w-4 text-slate-400" />
            <select
              name="agentId"
              defaultValue={conversation.assigneeId ?? ''}
              onChange={(e) => (e.currentTarget.form as HTMLFormElement).requestSubmit()}
              className="h-8 rounded-lg border border-slate-200 bg-white px-2 text-xs text-slate-600 focus:outline-none"
            >
              <option value="">Unassigned</option>
              {agents.map(({ user }) => (
                <option key={user.id} value={user.id}>
                  {user.name ?? user.email}
                </option>
              ))}
            </select>
          </form>

          {/* Status toggle */}
          <form
            action={async () => {
              'use server'
              await updateConversationStatus(
                slug,
                id,
                isResolved ? 'OPEN' : 'RESOLVED',
              )
            }}
          >
            <Button variant="outline" size="sm" type="submit">
              {isResolved ? (
                <>
                  <RefreshCw className="mr-1.5 h-3.5 w-3.5" />
                  Reopen
                </>
              ) : (
                <>
                  <CheckCircle className="mr-1.5 h-3.5 w-3.5" />
                  Resolve
                </>
              )}
            </Button>
          </form>
        </div>
      </div>

      {/* Contact info strip + labels */}
      <div className="flex flex-wrap items-center gap-4 border-b border-slate-100 bg-slate-50 px-4 py-2 text-xs text-slate-500">
        {conversation.contact && (
          <>
            {conversation.contact.email && <span>{conversation.contact.email}</span>}
            {conversation.contact.phone && <span>{conversation.contact.phone}</span>}
            {conversation.contact.company && <span>{conversation.contact.company}</span>}
            <Link
              href={`/${slug}/contacts/${conversation.contact.id}`}
              className="text-slate-700 hover:underline"
            >
              View contact →
            </Link>
          </>
        )}
        <div className="ml-auto">
          <LabelPicker
            workspace={slug}
            conversationId={id}
            allLabels={allLabels.map((l) => ({ id: l.id, title: l.title, color: l.color }))}
            currentLabelIds={conversation.labels.map((cl) => cl.labelId)}
          />
        </div>
      </div>

      {/* Messages */}
      <MessageThread
        conversationId={id}
        initialMessages={conversation.messages}
        agentId={session!.user!.id!}
      />

      {/* Reply box */}
      <ReplyBox workspace={slug} conversationId={id} />
    </div>
  )
}
