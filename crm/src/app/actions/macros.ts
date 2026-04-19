'use server'

import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'
import { executeActions, type AutomationAction } from '@/lib/automations'

async function getAccount(slug: string) {
  const session = await auth()
  const account = await db.account.findUnique({
    where: { slug },
    include: { members: { where: { userId: session!.user!.id } } },
  })
  if (!account || !account.members.length) throw new Error('Unauthorized')
  return account
}

export async function createMacro(_prev: unknown, formData: FormData) {
  const workspace = formData.get('workspace') as string
  const account = await getAccount(workspace)
  const name = formData.get('name') as string
  const actions = JSON.parse((formData.get('actions') as string) || '[]')

  await db.macro.create({ data: { accountId: account.id, name, actions } })
  revalidatePath(`/${workspace}/macros`)
  redirect(`/${workspace}/macros`)
}

export async function updateMacro(_prev: unknown, formData: FormData) {
  const workspace = formData.get('workspace') as string
  const id = formData.get('id') as string
  const account = await getAccount(workspace)
  const name = formData.get('name') as string
  const actions = JSON.parse((formData.get('actions') as string) || '[]')

  await db.macro.updateMany({
    where: { id, accountId: account.id },
    data: { name, actions },
  })
  revalidatePath(`/${workspace}/macros`)
  redirect(`/${workspace}/macros`)
}

export async function deleteMacro(workspace: string, id: string) {
  const account = await getAccount(workspace)
  await db.macro.deleteMany({ where: { id, accountId: account.id } })
  revalidatePath(`/${workspace}/macros`)
}

export async function runMacro(
  workspace: string,
  conversationId: string,
  macroId: string,
) {
  const account = await getAccount(workspace)
  const macro = await db.macro.findFirst({
    where: { id: macroId, accountId: account.id },
  })
  if (!macro) throw new Error('Macro not found')

  await executeActions(account.id, conversationId, macro.actions as AutomationAction[])
  revalidatePath(`/${workspace}/conversations/${conversationId}`)
}
