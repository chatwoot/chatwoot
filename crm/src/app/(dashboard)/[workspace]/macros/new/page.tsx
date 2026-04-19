import { notFound } from 'next/navigation'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'
import { createMacro } from '@/app/actions/macros'
import { MacroForm } from '@/components/macros/macro-form'

export default async function NewMacroPage({
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

  const [agents, labels] = await Promise.all([
    db.accountMember.findMany({
      where: { accountId: account.id },
      include: { user: true },
    }),
    db.label.findMany({ where: { accountId: account.id }, orderBy: { title: 'asc' } }),
  ])

  return (
    <div className="mx-auto max-w-2xl space-y-6">
      <div>
        <h1 className="text-2xl font-semibold text-slate-900">New macro</h1>
        <p className="text-sm text-slate-500">Build a reusable sequence of actions</p>
      </div>
      <div className="rounded-xl border border-slate-200 bg-white p-6">
        <MacroForm
          action={createMacro}
          workspace={slug}
          agents={agents.map(({ user }) => ({ id: user.id, name: user.name, email: user.email }))}
          labels={labels.map((l) => ({ id: l.id, title: l.title }))}
        />
      </div>
    </div>
  )
}
