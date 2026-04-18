import { notFound } from 'next/navigation'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'
import { updateContact, deleteContact } from '@/app/actions/contacts'
import { ContactForm } from '@/components/contacts/contact-form'
import { Avatar } from '@/components/ui/avatar'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { MessageSquare, Trash2 } from 'lucide-react'

export default async function ContactPage({
  params,
}: {
  params: Promise<{ workspace: string; id: string }>
}) {
  const { workspace: slug, id } = await params
  const session = await auth()

  const account = await db.account.findUnique({
    where: { slug },
    include: { members: { where: { userId: session!.user!.id } } },
  })
  if (!account || !account.members.length) notFound()

  const contact = await db.contact.findFirst({
    where: { id, accountId: account.id },
    include: {
      conversations: {
        orderBy: { createdAt: 'desc' },
        take: 5,
        include: { inbox: true },
      },
    },
  })
  if (!contact) notFound()

  const statusColors = {
    OPEN: 'success',
    RESOLVED: 'default',
    PENDING: 'warning',
    SNOOZED: 'outline',
  } as const

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between">
        <div className="flex items-center gap-4">
          <Avatar name={contact.name} className="h-12 w-12 text-base" />
          <div>
            <h1 className="text-2xl font-semibold text-slate-900">{contact.name}</h1>
            {contact.company && <p className="text-sm text-slate-500">{contact.company}</p>}
          </div>
        </div>
        <form
          action={async () => {
            'use server'
            await deleteContact(slug, id)
          }}
        >
          <Button variant="destructive" size="sm" type="submit">
            <Trash2 className="mr-1.5 h-3.5 w-3.5" />
            Delete
          </Button>
        </form>
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <div className="lg:col-span-2 space-y-5">
          <div className="rounded-xl border border-slate-200 bg-white p-5">
            <h2 className="mb-4 text-sm font-semibold text-slate-900">Edit contact</h2>
            <ContactForm
              action={updateContact}
              workspace={slug}
              defaultValues={{
                id: contact.id,
                name: contact.name,
                email: contact.email ?? undefined,
                phone: contact.phone ?? undefined,
                company: contact.company ?? undefined,
              }}
            />
          </div>
        </div>

        <div className="space-y-5">
          <div className="rounded-xl border border-slate-200 bg-white p-5">
            <h2 className="mb-3 flex items-center gap-2 text-sm font-semibold text-slate-900">
              <MessageSquare className="h-4 w-4" />
              Recent conversations
            </h2>
            {contact.conversations.length === 0 ? (
              <p className="text-sm text-slate-400">No conversations yet</p>
            ) : (
              <ul className="space-y-2">
                {contact.conversations.map((conv) => (
                  <li key={conv.id} className="flex items-center justify-between gap-2 text-sm">
                    <span className="truncate text-slate-600">{conv.inbox.name}</span>
                    <Badge variant={statusColors[conv.status]}>{conv.status}</Badge>
                  </li>
                ))}
              </ul>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
