import { notFound } from 'next/navigation'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'
import { updateTeam, deleteTeam, toggleTeamMember } from '@/app/actions/teams'
import { Avatar } from '@/components/ui/avatar'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Trash2 } from 'lucide-react'

export default async function TeamDetailPage({
  params,
}: {
  params: Promise<{ workspace: string; id: string }>
}) {
  const { workspace: slug, id } = await params
  const session = await auth()

  const account = await db.account.findUnique({
    where: { slug },
    include: {
      members: {
        include: { user: true },
      },
    },
  })
  if (!account || !account.members.find((m) => m.userId === session!.user!.id)) notFound()

  const team = await db.team.findFirst({
    where: { id, accountId: account.id },
    include: { members: { include: { user: true } } },
  })
  if (!team) notFound()

  const memberUserIds = new Set(team.members.map((m) => m.userId))

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-slate-900">{team.name}</h1>
          <p className="text-sm text-slate-500">{team.members.length} member{team.members.length !== 1 ? 's' : ''}</p>
        </div>
        <form
          action={async () => {
            'use server'
            await deleteTeam(slug, id)
          }}
        >
          <Button variant="destructive" size="sm" type="submit">
            <Trash2 className="mr-1.5 h-3.5 w-3.5" />
            Delete team
          </Button>
        </form>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        {/* Rename */}
        <div className="rounded-xl border border-slate-200 bg-white p-5">
          <h2 className="mb-4 text-sm font-semibold text-slate-900">Rename team</h2>
          <form
          action={async (fd: FormData) => {
            'use server'
            await updateTeam(undefined, fd)
          }}
          className="flex gap-3"
        >
            <input type="hidden" name="workspace" value={slug} />
            <input type="hidden" name="id" value={id} />
            <div className="flex-1 space-y-1.5">
              <Label htmlFor="teamName">Name</Label>
              <Input id="teamName" name="name" defaultValue={team.name} required />
            </div>
            <Button type="submit" className="mt-6">Save</Button>
          </form>
        </div>

        {/* Members */}
        <div className="rounded-xl border border-slate-200 bg-white p-5">
          <h2 className="mb-4 text-sm font-semibold text-slate-900">Members</h2>
          <ul className="space-y-2">
            {account.members.map(({ user, role }) => {
              const isMember = memberUserIds.has(user.id)
              return (
                <li key={user.id} className="flex items-center justify-between gap-3">
                  <div className="flex items-center gap-2.5">
                    <Avatar name={user.name ?? user.email} />
                    <div>
                      <p className="text-sm font-medium text-slate-900">
                        {user.name ?? user.email}
                      </p>
                      <p className="text-xs text-slate-400">{user.email}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <Badge variant="outline">{role}</Badge>
                    <form
                      action={async () => {
                        'use server'
                        await toggleTeamMember(slug, id, user.id)
                      }}
                    >
                      <Button
                        type="submit"
                        size="sm"
                        variant={isMember ? 'destructive' : 'outline'}
                      >
                        {isMember ? 'Remove' : 'Add'}
                      </Button>
                    </form>
                  </div>
                </li>
              )
            })}
          </ul>
        </div>
      </div>
    </div>
  )
}
