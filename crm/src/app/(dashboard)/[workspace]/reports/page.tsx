import { notFound } from 'next/navigation'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'
import { getReportData, type Period } from '@/lib/reports'
import { ReportsView } from '@/components/reports/reports-view'

export default async function ReportsPage({
  params,
  searchParams,
}: {
  params: Promise<{ workspace: string }>
  searchParams: Promise<{ period?: string }>
}) {
  const { workspace: slug } = await params
  const { period: rawPeriod = '30d' } = await searchParams
  const period = (['7d', '30d', '90d'].includes(rawPeriod) ? rawPeriod : '30d') as Period

  const session = await auth()

  const account = await db.account.findUnique({
    where: { slug },
    include: { members: { where: { userId: session!.user!.id } } },
  })
  if (!account || !account.members.length) notFound()

  const data = await getReportData(account.id, period)

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-slate-900">Reports</h1>
          <p className="text-sm text-slate-500">Workspace performance overview</p>
        </div>
        {/* Period selector rendered client-side */}
      </div>
      <ReportsView data={data} workspace={slug} />
    </div>
  )
}
