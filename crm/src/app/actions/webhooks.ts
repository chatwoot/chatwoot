'use server'

import { revalidatePath } from 'next/cache'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'

async function getAccount(slug: string) {
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

type WebhookState = { error: string } | undefined

export async function createWebhook(
  _prev: WebhookState,
  formData: FormData,
): Promise<WebhookState> {
  const workspace = formData.get('workspace') as string
  const url = formData.get('url') as string
  const secret = (formData.get('secret') as string) || undefined
  const events = formData.getAll('events') as string[]

  if (!url) return { error: 'URL is required' }

  try { new URL(url) } catch { return { error: 'Invalid URL' } }

  const account = await getAccount(workspace)
  await db.webhookSubscription.create({
    data: { accountId: account.id, url, events, secret },
  })
  revalidatePath(`/${workspace}/settings/webhooks`)
}

export async function deleteWebhook(workspace: string, id: string) {
  const account = await getAccount(workspace)
  await db.webhookSubscription.deleteMany({ where: { id, accountId: account.id } })
  revalidatePath(`/${workspace}/settings/webhooks`)
}

export async function toggleWebhook(workspace: string, id: string, active: boolean) {
  const account = await getAccount(workspace)
  await db.webhookSubscription.updateMany({
    where: { id, accountId: account.id },
    data: { active },
  })
  revalidatePath(`/${workspace}/settings/webhooks`)
}
