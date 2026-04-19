import { NextRequest, NextResponse } from 'next/server'
import { db } from '@/lib/db'
import { fireWebhooks } from '@/lib/webhooks'

export async function POST(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const { id: inboxId } = await params

  const inbox = await db.inbox.findUnique({ where: { id: inboxId } })
  if (!inbox || (inbox.channelType !== 'WHATSAPP' && inbox.channelType !== 'SMS')) {
    return new NextResponse('Not found', { status: 404 })
  }

  const form = await req.formData()
  const from = (form.get('From') as string) ?? ''
  const body = (form.get('Body') as string) ?? ''

  // Strip whatsapp: prefix from phone number
  const phone = from.replace(/^whatsapp:/i, '')
  if (!phone || !body) {
    return new NextResponse('<Response/>', {
      headers: { 'Content-Type': 'text/xml' },
    })
  }

  // Find or create contact by phone
  let contact = await db.contact.findFirst({
    where: { accountId: inbox.accountId, phone },
  })
  if (!contact) {
    contact = await db.contact.create({
      data: { accountId: inbox.accountId, name: phone, phone },
    })
  }

  // Find or create open conversation for this contact in this inbox
  let conversation = await db.conversation.findFirst({
    where: {
      accountId: inbox.accountId,
      inboxId,
      contactId: contact.id,
      status: 'OPEN',
    },
  })

  if (!conversation) {
    conversation = await db.conversation.create({
      data: {
        accountId: inbox.accountId,
        inboxId,
        contactId: contact.id,
        status: 'OPEN',
      },
    })

    await fireWebhooks(inbox.accountId, 'conversation_created', {
      conversationId: conversation.id,
    }).catch(() => {})
  }

  await db.message.create({
    data: {
      conversationId: conversation.id,
      content: body,
      contentType: 'text',
      authorType: 'contact',
      authorId: contact.id,
    },
  })

  await fireWebhooks(inbox.accountId, 'message_created', {
    conversationId: conversation.id,
    content: body,
  }).catch(() => {})

  return new NextResponse('<Response/>', {
    headers: { 'Content-Type': 'text/xml' },
  })
}
