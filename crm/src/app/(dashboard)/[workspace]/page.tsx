import { auth } from '@/lib/auth'
import { db } from '@/lib/db'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { MessageSquare, Users, Inbox, CheckCircle } from 'lucide-react'

export default async function WorkspacePage({
  params,
}: {
  params: Promise<{ workspace: string }>
}) {
  const { workspace: slug } = await params
  const session = await auth()

  const account = await db.account.findUnique({
    where: { slug },
    include: {
      _count: {
        select: {
          conversations: true,
          contacts: true,
          inboxes: true,
        },
      },
    },
  })

  const openConversations = await db.conversation.count({
    where: { accountId: account!.id, status: 'OPEN' },
  })

  const stats = [
    {
      label: 'Open Conversations',
      value: openConversations,
      icon: MessageSquare,
    },
    {
      label: 'Total Conversations',
      value: account!._count.conversations,
      icon: CheckCircle,
    },
    { label: 'Contacts', value: account!._count.contacts, icon: Users },
    { label: 'Inboxes', value: account!._count.inboxes, icon: Inbox },
  ]

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold text-slate-900">Overview</h1>
        <p className="text-sm text-slate-500">
          Welcome back, {session?.user?.name ?? 'there'}
        </p>
      </div>
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {stats.map(({ label, value, icon: Icon }) => (
          <Card key={label}>
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-slate-500">
                {label}
              </CardTitle>
              <Icon className="h-4 w-4 text-slate-400" />
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold text-slate-900">{value}</div>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  )
}
