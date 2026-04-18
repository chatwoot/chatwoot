'use server'

import { revalidatePath } from 'next/cache'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'
import bcrypt from 'bcryptjs'
import type { Role } from '@/generated/prisma/client'

async function resolveAccount(slug: string, userId: string) {
  const member = await db.accountMember.findFirst({
    where: { account: { slug }, userId, role: { in: ['OWNER', 'ADMIN'] } },
    include: { account: true },
  })
  if (!member) throw new Error('Unauthorized')
  return member.account
}

type AgentState = { error: string } | undefined

export async function inviteAgent(
  _prev: AgentState,
  formData: FormData,
): Promise<AgentState> {
  const session = await auth()
  if (!session?.user?.id) return { error: 'Unauthorized' }

  const slug = formData.get('workspace') as string
  const name = (formData.get('name') as string)?.trim()
  const email = (formData.get('email') as string)?.trim()
  const password = formData.get('password') as string
  const role = (formData.get('role') as Role) || 'AGENT'

  if (!name || !email || !password) return { error: 'All fields are required' }
  if (password.length < 8) return { error: 'Password must be at least 8 characters' }

  const account = await resolveAccount(slug, session.user.id)

  let user = await db.user.findUnique({ where: { email } })

  if (user) {
    const alreadyMember = await db.accountMember.findUnique({
      where: { accountId_userId: { accountId: account.id, userId: user.id } },
    })
    if (alreadyMember) return { error: 'This user is already a member of this workspace' }
  } else {
    user = await db.user.create({
      data: { name, email, password: await bcrypt.hash(password, 12) },
    })
  }

  await db.accountMember.create({
    data: { accountId: account.id, userId: user.id, role },
  })

  revalidatePath(`/${slug}/settings/agents`)
}

export async function updateAgentRole(slug: string, userId: string, role: Role) {
  const session = await auth()
  if (!session?.user?.id) throw new Error('Unauthorized')

  const account = await resolveAccount(slug, session.user.id)
  await db.accountMember.updateMany({
    where: { accountId: account.id, userId },
    data: { role },
  })

  revalidatePath(`/${slug}/settings/agents`)
}

export async function removeAgent(slug: string, userId: string) {
  const session = await auth()
  if (!session?.user?.id) throw new Error('Unauthorized')
  if (session.user.id === userId) throw new Error('Cannot remove yourself')

  const account = await resolveAccount(slug, session.user.id)
  await db.accountMember.deleteMany({ where: { accountId: account.id, userId } })

  revalidatePath(`/${slug}/settings/agents`)
}
