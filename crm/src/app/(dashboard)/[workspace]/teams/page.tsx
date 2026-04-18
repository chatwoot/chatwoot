import { notFound } from 'next/navigation'
import Link from 'next/link'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'
import { NewTeamForm } from '@/components/teams/new-team-form'
import { Users } from 'lucide-react'

export default async function TeamsPage({
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
      teams: {
        orderBy: { createdAt: 'asc' },
        include: { _count: { select: { members: true, conversations: true } } },
      },
    },
  })
  if (!account || !account.members.length) notFound()

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold text-slate-900">Teams</h1>
        <p className="text-sm text-slate-500">Group agents into teams for assignment</p>
      </div>

      <NewTeamForm workspace={slug} />

      {account.teams.length === 0 ? (
        <div className="rounded-xl border border-dashed border-slate-200 py-12 text-center text-sm text-slate-400">
          No teams yet. Create your first team above.
        </div>
      ) : (
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {account.teams.map((team) => (
            <Link
              key={team.id}
              href={`/${slug}/teams/${team.id}`}
              className="flex items-center gap-3 rounded-xl border border-slate-200 bg-white p-4 hover:bg-slate-50 transition-colors"
            >
              <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-slate-100">
                <Users className="h-4 w-4 text-slate-500" />
              </div>
              <div>
                <p className="text-sm font-semibold text-slate-900">{team.name}</p>
                <p className="text-xs text-slate-400">
                  {team._count.members} agent{team._count.members !== 1 ? 's' : ''}
                </p>
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  )
}
