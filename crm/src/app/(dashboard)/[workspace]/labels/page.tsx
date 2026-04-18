import { notFound } from 'next/navigation'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'
import { LabelManager } from '@/components/labels/label-manager'

export default async function LabelsPage({
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
      labels: { orderBy: { title: 'asc' } },
    },
  })
  if (!account || !account.members.length) notFound()

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-2xl font-semibold text-slate-900">Labels</h1>
        <p className="text-sm text-slate-500">
          Organize conversations with color-coded labels
        </p>
      </div>
      <LabelManager
        workspace={slug}
        labels={account.labels.map((l) => ({ id: l.id, title: l.title, color: l.color }))}
      />
    </div>
  )
}
