'use server'

import { revalidatePath } from 'next/cache'
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

type LabelState = { error: string } | undefined

export async function createLabel(
  _prev: LabelState,
  formData: FormData,
): Promise<LabelState> {
  const session = await auth()
  if (!session?.user?.id) return { error: 'Unauthorized' }

  const slug = formData.get('workspace') as string
  const title = (formData.get('title') as string)?.trim()
  const color = (formData.get('color') as string) || '#6C7589'

  if (!title) return { error: 'Title is required' }

  const account = await resolveAccount(slug, session.user.id)

  const exists = await db.label.findUnique({
    where: { accountId_title: { accountId: account.id, title } },
  })
  if (exists) return { error: 'Label already exists' }

  await db.label.create({ data: { accountId: account.id, title, color } })
  revalidatePath(`/${slug}/labels`)
}

export async function updateLabel(
  _prev: LabelState,
  formData: FormData,
): Promise<LabelState> {
  const session = await auth()
  if (!session?.user?.id) return { error: 'Unauthorized' }

  const slug = formData.get('workspace') as string
  const id = formData.get('id') as string
  const title = (formData.get('title') as string)?.trim()
  const color = (formData.get('color') as string) || '#6C7589'

  if (!title) return { error: 'Title is required' }

  const account = await resolveAccount(slug, session.user.id)
  await db.label.updateMany({ where: { id, accountId: account.id }, data: { title, color } })
  revalidatePath(`/${slug}/labels`)
}

export async function deleteLabel(slug: string, id: string) {
  const session = await auth()
  if (!session?.user?.id) throw new Error('Unauthorized')

  const account = await resolveAccount(slug, session.user.id)
  await db.label.deleteMany({ where: { id, accountId: account.id } })
  revalidatePath(`/${slug}/labels`)
}

export async function toggleConversationLabel(
  slug: string,
  conversationId: string,
  labelId: string,
) {
  const session = await auth()
  if (!session?.user?.id) throw new Error('Unauthorized')

  const account = await resolveAccount(slug, session.user.id)
  const conversation = await db.conversation.findFirst({
    where: { id: conversationId, accountId: account.id },
  })
  if (!conversation) throw new Error('Not found')

  const existing = await db.conversationLabel.findUnique({
    where: { conversationId_labelId: { conversationId, labelId } },
  })

  if (existing) {
    await db.conversationLabel.delete({
      where: { conversationId_labelId: { conversationId, labelId } },
    })
  } else {
    await db.conversationLabel.create({ data: { conversationId, labelId } })
  }

  revalidatePath(`/${slug}/conversations/${conversationId}`)
}
