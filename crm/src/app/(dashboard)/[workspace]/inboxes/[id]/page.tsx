import { notFound } from 'next/navigation'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'
import { updateInbox, deleteInbox } from '@/app/actions/inboxes'
import { InboxForm } from '@/components/inboxes/inbox-form'
import { Button } from '@/components/ui/button'
import { Trash2, Copy } from 'lucide-react'
import { CopyButton } from '@/components/ui/copy-button'

export default async function InboxSettingsPage({
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

  const inbox = await db.inbox.findFirst({ where: { id, accountId: account.id } })
  if (!inbox) notFound()

  const origin = process.env.NEXTAUTH_URL ?? 'http://localhost:3000'
  const webhookUrl = `${origin}/api/inboxes/${inbox.id}/email`
  const widgetUrl = `${origin}/widget/${inbox.id}`
  const embedCode = `<iframe src="${widgetUrl}" width="400" height="600" frameborder="0"></iframe>`

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-slate-900">{inbox.name}</h1>
          <p className="text-sm text-slate-500">Inbox settings</p>
        </div>
        <form
          action={async () => {
            'use server'
            await deleteInbox(slug, id)
          }}
        >
          <Button variant="destructive" size="sm" type="submit">
            <Trash2 className="mr-1.5 h-3.5 w-3.5" />
            Delete inbox
          </Button>
        </form>
      </div>

      <div className="grid gap-6 lg:grid-cols-3">
        <div className="lg:col-span-2">
          <div className="rounded-xl border border-slate-200 bg-white p-5">
            <h2 className="mb-4 text-sm font-semibold text-slate-900">Configuration</h2>
            <InboxForm
              action={updateInbox}
              workspace={slug}
              defaultValues={{
                id: inbox.id,
                name: inbox.name,
                channelType: inbox.channelType,
                email: inbox.email ?? undefined,
                emailFromName: inbox.emailFromName ?? undefined,
                widgetColor: inbox.widgetColor,
              }}
            />
          </div>
        </div>

        <div className="space-y-4">
          {inbox.channelType === 'EMAIL' && (
            <div className="rounded-xl border border-slate-200 bg-white p-5">
              <h2 className="mb-3 text-sm font-semibold text-slate-900">Inbound webhook</h2>
              <p className="mb-3 text-xs text-slate-500">
                Configure your email provider (Mailgun, SendGrid) to forward inbound emails to this URL:
              </p>
              <div className="flex items-center gap-2 rounded-lg bg-slate-50 p-2">
                <code className="flex-1 truncate text-xs text-slate-700">{webhookUrl}</code>
                <CopyButton text={webhookUrl} />
              </div>
            </div>
          )}

          {inbox.channelType === 'LIVE_CHAT' && (
            <div className="rounded-xl border border-slate-200 bg-white p-5">
              <h2 className="mb-3 text-sm font-semibold text-slate-900">Embed code</h2>
              <p className="mb-3 text-xs text-slate-500">
                Add this to your website to show the chat widget:
              </p>
              <div className="flex items-start gap-2 rounded-lg bg-slate-50 p-2">
                <code className="flex-1 break-all text-xs text-slate-700">{embedCode}</code>
                <CopyButton text={embedCode} />
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
