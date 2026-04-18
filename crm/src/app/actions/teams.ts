'use server'

import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'

async function resolveAccount(slug: string, userId: string) {
  const member = await db.accountMember.findFirst({
    where: { account: { slug }, userId },
    include: { account: true },
  })
  if (!member) throw new Error('Unauthorized')
  return member.account
}

type TeamState = { error: string } | undefined

export async function createTeam(
  _prev: TeamState,
  formData: FormData,
): Promise<TeamState> {
  const session = await auth()
  if (!session?.user?.id) return { error: 'Unauthorized' }

  const slug = formData.get('workspace') as string
  const name = (formData.get('name') as string)?.trim()

  if (!name) return { error: 'Name is required' }

  const account = await resolveAccount(slug, session.user.id)

  const exists = await db.team.findUnique({
    where: { accountId_name: { accountId: account.id, name } },
  })
  if (exists) return { error: 'Team already exists' }

  const team = await db.team.create({
    data: {
      accountId: account.id,
      name,
      members: { create: { userId: session.user.id } },
    },
  })

  revalidatePath(`/${slug}/teams`)
  redirect(`/${slug}/teams/${team.id}`)
}

export async function updateTeam(
  _prev: TeamState,
  formData: FormData,
): Promise<TeamState> {
  const session = await auth()
  if (!session?.user?.id) return { error: 'Unauthorized' }

  const slug = formData.get('workspace') as string
  const id = formData.get('id') as string
  const name = (formData.get('name') as string)?.trim()

  if (!name) return { error: 'Name is required' }

  const account = await resolveAccount(slug, session.user.id)
  await db.team.updateMany({ where: { id, accountId: account.id }, data: { name } })

  revalidatePath(`/${slug}/teams`)
  revalidatePath(`/${slug}/teams/${id}`)
}

export async function deleteTeam(slug: string, id: string) {
  const session = await auth()
  if (!session?.user?.id) throw new Error('Unauthorized')

  const account = await resolveAccount(slug, session.user.id)
  await db.team.deleteMany({ where: { id, accountId: account.id } })

  revalidatePath(`/${slug}/teams`)
  redirect(`/${slug}/teams`)
}

export async function toggleTeamMember(slug: string, teamId: string, userId: string) {
  const session = await auth()
  if (!session?.user?.id) throw new Error('Unauthorized')

  const account = await resolveAccount(slug, session.user.id)
  const team = await db.team.findFirst({ where: { id: teamId, accountId: account.id } })
  if (!team) throw new Error('Team not found')

  const existing = await db.teamMember.findUnique({
    where: { teamId_userId: { teamId, userId } },
  })

  if (existing) {
    await db.teamMember.delete({ where: { teamId_userId: { teamId, userId } } })
  } else {
    await db.teamMember.create({ data: { teamId, userId } })
  }

  revalidatePath(`/${slug}/teams/${teamId}`)
}
