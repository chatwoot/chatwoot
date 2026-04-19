'use server'

import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'

async function getAdminAccount(slug: string) {
  const session = await auth()
  const account = await db.account.findUnique({
    where: { slug },
    include: { members: { where: { userId: session!.user!.id } } },
  })
  if (!account || !account.members.length) throw new Error('Unauthorized')
  const role = account.members[0].role
  if (role !== 'OWNER' && role !== 'ADMIN') throw new Error('Forbidden')
  return account
}

export async function createAutomation(workspace: string, formData: FormData) {
  const account = await getAdminAccount(workspace)
  const name = formData.get('name') as string
  const event = formData.get('event') as string
  const conditions = JSON.parse((formData.get('conditions') as string) || '[]')
  const actions = JSON.parse((formData.get('actions') as string) || '[]')

  await db.automation.create({
    data: { accountId: account.id, name, event, conditions, actions },
  })
  revalidatePath(`/${workspace}/automations`)
  redirect(`/${workspace}/automations`)
}

export async function updateAutomation(
  workspace: string,
  id: string,
  formData: FormData,
) {
  const account = await getAdminAccount(workspace)
  const name = formData.get('name') as string
  const event = formData.get('event') as string
  const conditions = JSON.parse((formData.get('conditions') as string) || '[]')
  const actions = JSON.parse((formData.get('actions') as string) || '[]')

  await db.automation.updateMany({
    where: { id, accountId: account.id },
    data: { name, event, conditions, actions },
  })
  revalidatePath(`/${workspace}/automations`)
  redirect(`/${workspace}/automations`)
}

export async function toggleAutomation(
  workspace: string,
  id: string,
  active: boolean,
) {
  const account = await getAdminAccount(workspace)
  await db.automation.updateMany({
    where: { id, accountId: account.id },
    data: { active },
  })
  revalidatePath(`/${workspace}/automations`)
}

export async function deleteAutomation(workspace: string, id: string) {
  const account = await getAdminAccount(workspace)
  await db.automation.deleteMany({ where: { id, accountId: account.id } })
  revalidatePath(`/${workspace}/automations`)
}
