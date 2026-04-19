import { notFound } from 'next/navigation'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'
import { updateAutomation } from '@/app/actions/automations'
import { AutomationForm } from '@/components/automations/automation-form'

export default async function EditAutomationPage({
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

  const [automation, agents, labels, inboxes] = await Promise.all([
    db.automation.findFirst({ where: { id, accountId: account.id } }),
    db.accountMember.findMany({
      where: { accountId: account.id },
      include: { user: true },
    }),
    db.label.findMany({ where: { accountId: account.id }, orderBy: { title: 'asc' } }),
    db.inbox.findMany({ where: { accountId: account.id }, orderBy: { name: 'asc' } }),
  ])
  if (!automation) notFound()

  const boundAction = updateAutomation.bind(null, slug, id)

  return (
    <div className="mx-auto max-w-2xl space-y-6">
      <div>
        <h1 className="text-2xl font-semibold text-slate-900">Edit automation</h1>
        <p className="text-sm text-slate-500">{automation.name}</p>
      </div>
      <div className="rounded-xl border border-slate-200 bg-white p-6">
        <AutomationForm
          action={boundAction}
          initial={{
            name: automation.name,
            event: automation.event,
            conditions: automation.conditions as { attribute: string; operator: string; value: string }[],
            actions: automation.actions as { type: string; params: Record<string, string> }[],
          }}
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
