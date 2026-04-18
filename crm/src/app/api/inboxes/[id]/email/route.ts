import { NextRequest, NextResponse } from 'next/server'
import { db } from '@/lib/db'

/**
 * Inbound email webhook — compatible with Mailgun, SendGrid Inbound Parse, and Postmark.
 * Configure your email provider to POST parsed emails to this endpoint.
 */
export async function POST(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const { id: inboxId } = await params

  const inbox = await db.inbox.findUnique({ where: { id: inboxId } })
  if (!inbox || inbox.channelType !== 'EMAIL') {
    return NextResponse.json({ error: 'Inbox not found' }, { status: 404 })
  }

  const contentType = req.headers.get('content-type') ?? ''
  let from = ''
  let subject = ''
  let body = ''
  let msgId = ''

  if (contentType.includes('application/json')) {
    // Postmark / custom JSON
    const json = await req.json()
    from = json.From ?? json.from ?? ''
    subject = json.Subject ?? json.subject ?? '(no subject)'
    body = json.HtmlBody ?? json.TextBody ?? json.html ?? json.text ?? ''
    msgId = json.MessageID ?? json['Message-Id'] ?? ''
  } else {
    // Mailgun / SendGrid multipart form
    const fd = await req.formData()
    from = (fd.get('sender') ?? fd.get('from') ?? '') as string
    subject = (fd.get('subject') ?? '(no subject)') as string
    body = (fd.get('body-html') ?? fd.get('body-text') ?? fd.get('html') ?? fd.get('text') ?? '') as string
    msgId = (fd.get('Message-Id') ?? '') as string
  }

  if (!from) return NextResponse.json({ error: 'Missing from' }, { status: 400 })

  // Extract plain email address from "Name <email>" format
  const fromEmail = from.match(/<(.+?)>/) ? from.match(/<(.+?)>/)![1] : from.trim()
  const fromName = from.includes('<') ? from.split('<')[0].trim().replace(/"/g, '') : fromEmail

  // Upsert contact
  let contact = await db.contact.findUnique({
    where: { accountId_email: { accountId: inbox.accountId, email: fromEmail } },
  })
  if (!contact) {
    contact = await db.contact.create({
      data: { accountId: inbox.accountId, name: fromName || fromEmail, email: fromEmail },
    })
  }

  // Create conversation
  const conversation = await db.conversation.create({
    data: {
      accountId: inbox.accountId,
      inboxId,
      contactId: contact.id,
      subject,
      fromEmail,
      toEmail: inbox.email ?? undefined,
      emailMsgId: msgId || undefined,
      status: 'OPEN',
    },
  })

  // Create initial message
  const isHtml = body.trim().startsWith('<')
  await db.message.create({
    data: {
      conversationId: conversation.id,
      content: body,
      contentType: isHtml ? 'html' : 'text',
      authorType: 'contact',
      authorId: contact.id,
      authorEmail: fromEmail,
    },
  })

  return NextResponse.json({ ok: true, conversationId: conversation.id })
}
