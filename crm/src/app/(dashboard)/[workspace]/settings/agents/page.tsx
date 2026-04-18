import { notFound } from 'next/navigation'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'
import { removeAgent, updateAgentRole } from '@/app/actions/agents'
import { InviteAgentForm } from '@/components/teams/invite-agent-form'
import { Avatar } from '@/components/ui/avatar'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Trash2 } from 'lucide-react'
import type { Role } from '@/generated/prisma/client'

const ROLE_BADGE: Record<Role, 'default' | 'warning' | 'success'> = {
  OWNER: 'success',
  ADMIN: 'warning',
  AGENT: 'default',
}

export default async function AgentsPage({
  params,
}: {
  params: Promise<{ workspace: string }>
}) {
  const { workspace: slug } = await params
  const session = await auth()

  const account = await db.account.findUnique({
    where: { slug },
    include: {
      members: {
        include: { user: true },
        orderBy: { createdAt: 'asc' },
      },
    },
  })
  if (!account) notFound()

  const currentMember = account.members.find((m) => m.userId === session!.user!.id)
  if (!currentMember) notFound()

  const isAdmin = ['OWNER', 'ADMIN'].includes(currentMember.role)

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold text-slate-900">Agents</h1>
        <p className="text-sm text-slate-500">
          {account.members.length} member{account.members.length !== 1 ? 's' : ''} in this workspace
        </p>
      </div>

      {isAdmin && <InviteAgentForm workspace={slug} />}

      <div className="rounded-xl border border-slate-200 bg-white overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-slate-100 bg-slate-50 text-left text-xs font-medium text-slate-500 uppercase tracking-wide">
              <th className="px-4 py-3">Agent</th>
              <th className="px-4 py-3">Role</th>
              {isAdmin && <th className="px-4 py-3">Actions</th>}
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {account.members.map(({ user, role }) => {
              const isSelf = user.id === session!.user!.id
              return (
                <tr key={user.id} className="hover:bg-slate-50">
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-3">
                      <Avatar name={user.name ?? user.email} />
                      <div>
                        <p className="font-medium text-slate-900">
                          {user.name ?? '—'}
                          {isSelf && <span className="ml-1.5 text-xs text-slate-400">(you)</span>}
                        </p>
                        <p className="text-xs text-slate-400">{user.email}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-4 py-3">
                    {isAdmin && !isSelf ? (
                      <form
                        action={async (fd: FormData) => {
                          'use server'
                          await updateAgentRole(slug, user.id, fd.get('role') as Role)
                        }}
                        className="flex items-center gap-2"
                      >
                        <select
                          name="role"
                          defaultValue={role}
                          onChange={(e) => (e.currentTarget.form as HTMLFormElement).requestSubmit()}
                          className="h-7 rounded-lg border border-slate-200 bg-white px-2 text-xs focus:outline-none focus:ring-2 focus:ring-slate-900"
                        >
                          <option value="AGENT">Agent</option>
                          <option value="ADMIN">Admin</option>
                          <option value="OWNER">Owner</option>
                        </select>
                      </form>
                    ) : (
                      <Badge variant={ROLE_BADGE[role]}>{role}</Badge>
                    )}
                  </td>
                  {isAdmin && (
                    <td className="px-4 py-3">
                      {!isSelf && (
                        <form
                          action={async () => {
                            'use server'
                            await removeAgent(slug, user.id)
                          }}
                        >
                          <Button
                            size="sm"
                            variant="ghost"
                            type="submit"
                            className="text-red-400 hover:text-red-600"
                          >
                            <Trash2 className="h-3.5 w-3.5" />
                          </Button>
                        </form>
                      )}
                    </td>
                  )}
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
    </div>
  )
}
