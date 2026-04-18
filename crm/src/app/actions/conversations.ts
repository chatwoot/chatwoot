'use server'

import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'
import { sendEmail } from '@/lib/email'

async function resolveAccount(slug: string, userId: string) {
  const member = await db.accountMember.findFirst({
    where: { account: { slug }, userId },
    include: { account: true },
  })
  if (!member) throw new Error('Unauthorized')
  return member.account
}

type ConvState = { error: string } | undefined

export async function createConversation(
  _prev: ConvState,
  formData: FormData,
): Promise<ConvState> {
  const session = await auth()
  if (!session?.user?.id) return { error: 'Unauthorized' }

  const slug = formData.get('workspace') as string
  const inboxId = formData.get('inboxId') as string
  const contactId = (formData.get('contactId') as string) || undefined
  const subject = (formData.get('subject') as string) || undefined

  if (!inboxId) return { error: 'Inbox is required' }

  const account = await resolveAccount(slug, session.user.id)

  const inbox = await db.inbox.findFirst({ where: { id: inboxId, accountId: account.id } })
  if (!inbox) return { error: 'Inbox not found' }

  const conversation = await db.conversation.create({
    data: {
      accountId: account.id,
      inboxId,
      contactId,
      subject,
      assigneeId: session.user.id,
    },
  })

  revalidatePath(`/${slug}/conversations`)
  redirect(`/${slug}/conversations/${conversation.id}`)
}

export async function sendMessage(
  _prev: ConvState,
  formData: FormData,
): Promise<ConvState> {
  const session = await auth()
  if (!session?.user?.id) return { error: 'Unauthorized' }

  const slug = formData.get('workspace') as string
  const conversationId = formData.get('conversationId') as string
  const content = (formData.get('content') as string)?.trim()
  const isPrivate = formData.get('private') === 'true'

  if (!content) return { error: 'Message cannot be empty' }

  const account = await resolveAccount(slug, session.user.id)
  const conversation = await db.conversation.findFirst({
    where: { id: conversationId, accountId: account.id },
    include: { inbox: true },
  })
  if (!conversation) return { error: 'Conversation not found' }

  await db.message.create({
    data: {
      conversationId,
      content,
      contentType: 'text',
      authorType: 'agent',
      authorId: session.user.id,
      private: isPrivate,
    },
  })

  await db.conversation.update({
    where: { id: conversationId },
    data: { updatedAt: new Date() },
  })

  // Send outbound email for EMAIL inboxes (skip private notes)
  if (
    !isPrivate &&
    conversation.inbox.channelType === 'EMAIL' &&
    conversation.fromEmail &&
    conversation.inbox.email &&
    process.env.RESEND_API_KEY
  ) {
    await sendEmail({
      to: conversation.fromEmail,
      from: conversation.inbox.email,
      fromName: conversation.inbox.emailFromName ?? undefined,
      subject: `Re: ${conversation.subject ?? 'Your support request'}`,
      text: content,
      inReplyTo: conversation.emailMsgId ?? undefined,
    }).catch(() => {
      // Log but don't fail — message already saved
    })
  }

  revalidatePath(`/${slug}/conversations/${conversationId}`)
}

export async function updateConversationStatus(
  slug: string,
  conversationId: string,
  status: 'OPEN' | 'RESOLVED' | 'PENDING' | 'SNOOZED',
) {
  const session = await auth()
  if (!session?.user?.id) throw new Error('Unauthorized')

  const account = await resolveAccount(slug, session.user.id)
  await db.conversation.updateMany({
    where: { id: conversationId, accountId: account.id },
    data: { status },
  })

  revalidatePath(`/${slug}/conversations`)
  revalidatePath(`/${slug}/conversations/${conversationId}`)
}

export async function assignConversation(
  slug: string,
  conversationId: string,
  agentId: string | null,
) {
  const session = await auth()
  if (!session?.user?.id) throw new Error('Unauthorized')

  const account = await resolveAccount(slug, session.user.id)
  await db.conversation.updateMany({
    where: { id: conversationId, accountId: account.id },
    data: { assigneeId: agentId },
  })

  revalidatePath(`/${slug}/conversations/${conversationId}`)
}
