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

type InboxState = { error: string } | undefined

export async function createInbox(
  _prev: InboxState,
  formData: FormData,
): Promise<InboxState> {
  const session = await auth()
  if (!session?.user?.id) return { error: 'Unauthorized' }

  const slug = formData.get('workspace') as string
  const name = formData.get('name') as string
  const channelType = (formData.get('channelType') as string) || 'LIVE_CHAT'
  const email = (formData.get('email') as string) || undefined
  const emailFromName = (formData.get('emailFromName') as string) || undefined
  const widgetColor = (formData.get('widgetColor') as string) || '#1F93FF'

  if (!name) return { error: 'Name is required' }

  const account = await resolveAccount(slug, session.user.id)

  const inbox = await db.inbox.create({
    data: {
      accountId: account.id,
      name,
      channelType: channelType as 'LIVE_CHAT' | 'EMAIL' | 'API',
      email,
      emailFromName,
      widgetColor,
    },
  })

  revalidatePath(`/${slug}/inboxes`)
  redirect(`/${slug}/inboxes/${inbox.id}`)
}

export async function updateInbox(
  _prev: InboxState,
  formData: FormData,
): Promise<InboxState> {
  const session = await auth()
  if (!session?.user?.id) return { error: 'Unauthorized' }

  const slug = formData.get('workspace') as string
  const id = formData.get('id') as string
  const name = formData.get('name') as string
  const email = (formData.get('email') as string) || undefined
  const emailFromName = (formData.get('emailFromName') as string) || undefined
  const widgetColor = (formData.get('widgetColor') as string) || '#1F93FF'

  if (!name) return { error: 'Name is required' }

  const account = await resolveAccount(slug, session.user.id)
  const inbox = await db.inbox.findFirst({ where: { id, accountId: account.id } })
  if (!inbox) return { error: 'Inbox not found' }

  await db.inbox.update({
    where: { id },
    data: { name, email, emailFromName, widgetColor },
  })

  revalidatePath(`/${slug}/inboxes`)
  revalidatePath(`/${slug}/inboxes/${id}`)
  redirect(`/${slug}/inboxes/${id}`)
}

export async function deleteInbox(slug: string, id: string) {
  const session = await auth()
  if (!session?.user?.id) throw new Error('Unauthorized')

  const account = await resolveAccount(slug, session.user.id)
  await db.inbox.deleteMany({ where: { id, accountId: account.id } })

  revalidatePath(`/${slug}/inboxes`)
  redirect(`/${slug}/inboxes`)
}
