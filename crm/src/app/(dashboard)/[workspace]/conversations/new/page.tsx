import { notFound } from 'next/navigation'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'
import { NewConversationForm } from '@/components/conversations/new-conversation-form'

export default async function NewConversationPage({
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
      inboxes: true,
      contacts: { orderBy: { name: 'asc' }, take: 200 },
    },
  })
  if (!account || !account.members.length) notFound()

  if (account.inboxes.length === 0) {
    return (
      <div className="space-y-4">
        <h1 className="text-2xl font-semibold text-slate-900">New conversation</h1>
        <p className="text-sm text-slate-500">
          You need to create an inbox first before starting a conversation.
        </p>
      </div>
    )
  }

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-2xl font-semibold text-slate-900">New conversation</h1>
        <p className="text-sm text-slate-500">Start a conversation with a contact</p>
      </div>
      <NewConversationForm
        workspace={slug}
        inboxes={account.inboxes.map((i) => ({ id: i.id, name: i.name }))}
        contacts={account.contacts.map((c) => ({ id: c.id, name: c.name, email: c.email }))}
      />
    </div>
  )
}
