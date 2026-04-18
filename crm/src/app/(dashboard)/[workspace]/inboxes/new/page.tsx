import { createInbox } from '@/app/actions/inboxes'
import { InboxForm } from '@/components/inboxes/inbox-form'

export default async function NewInboxPage({
  params,
}: {
  params: Promise<{ workspace: string }>
}) {
  const { workspace } = await params

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-2xl font-semibold text-slate-900">New inbox</h1>
        <p className="text-sm text-slate-500">Configure a new channel to receive conversations</p>
      </div>
      <InboxForm action={createInbox} workspace={workspace} />
    </div>
  )
}
