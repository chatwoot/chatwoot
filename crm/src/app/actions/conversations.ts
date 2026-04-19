'use server'

import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'
import { sendEmail } from '@/lib/email'
import { processEvent } from '@/lib/automations'
import { fireWebhooks } from '@/lib/webhooks'
import { sendTwilioMessage } from '@/lib/twilio'

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

  await Promise.all([
    processEvent(account.id, 'conversation_created', conversation.id).catch(() => {}),
    fireWebhooks(account.id, 'conversation_created', { conversationId: conversation.id }).catch(() => {}),
  ])

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
    include: { inbox: true, contact: true },
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

  if (!isPrivate) {
    await Promise.all([
      processEvent(account.id, 'message_created', conversationId).catch(() => {}),
      fireWebhooks(account.id, 'message_created', { conversationId, content }).catch(() => {}),
    ])
  }

  await db.conversation.update({
    where: { id: conversationId },
    data: { updatedAt: new Date() },
  })

  // Outbound email for EMAIL inboxes
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
    }).catch(() => {})
  }

  // Outbound WhatsApp/SMS via Twilio
  const { channelType } = conversation.inbox
  if (
    !isPrivate &&
    (channelType === 'WHATSAPP' || channelType === 'SMS') &&
    conversation.inbox.twilioAccountSid &&
    conversation.inbox.twilioAuthToken &&
    conversation.inbox.twilioPhoneNumber &&
    conversation.contact?.phone
  ) {
    await sendTwilioMessage({
      accountSid: conversation.inbox.twilioAccountSid,
      authToken: conversation.inbox.twilioAuthToken,
      from: conversation.inbox.twilioPhoneNumber,
      to: conversation.contact.phone,
      body: content,
      channelType,
    }).catch(() => {})
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

  await Promise.all([
    processEvent(account.id, 'conversation_updated', conversationId).catch(() => {}),
    fireWebhooks(account.id, 'conversation_updated', { conversationId, status }).catch(() => {}),
  ])

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
