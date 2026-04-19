import { notFound } from 'next/navigation'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'
import { createAutomation } from '@/app/actions/automations'
import { AutomationForm } from '@/components/automations/automation-form'

export default async function NewAutomationPage({
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

  const [agents, labels, inboxes] = await Promise.all([
    db.accountMember.findMany({
      where: { accountId: account.id },
      include: { user: true },
    }),
    db.label.findMany({ where: { accountId: account.id }, orderBy: { title: 'asc' } }),
    db.inbox.findMany({ where: { accountId: account.id }, orderBy: { name: 'asc' } }),
  ])

  const boundAction = createAutomation.bind(null, slug)

  return (
    <div className="mx-auto max-w-2xl space-y-6">
      <div>
        <h1 className="text-2xl font-semibold text-slate-900">New automation</h1>
        <p className="text-sm text-slate-500">Define a trigger event, conditions, and actions</p>
      </div>
      <div className="rounded-xl border border-slate-200 bg-white p-6">
        <AutomationForm
          action={boundAction}
          agents={agents.map(({ user }) => ({
            id: user.id,
            name: user.name,
            email: user.email,
          }))}
          labels={labels.map((l) => ({ id: l.id, title: l.title }))}
          inboxes={inboxes.map((b) => ({ id: b.id, name: b.name }))}
        />
      </div>
    </div>
  )
}
