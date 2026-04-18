import { NextRequest, NextResponse } from 'next/server'
import { db } from '@/lib/db'

export async function POST(
  req: NextRequest,
  { params }: { params: Promise<{ inboxId: string }> },
) {
  const { inboxId } = await params
  const body = await req.json()
  const { name, email } = body as { name?: string; email?: string }

  const inbox = await db.inbox.findUnique({ where: { id: inboxId } })
  if (!inbox) return NextResponse.json({ error: 'Inbox not found' }, { status: 404 })

  let contact = email
    ? await db.contact.findUnique({
        where: { accountId_email: { accountId: inbox.accountId, email } },
      })
    : null

  if (!contact) {
    contact = await db.contact.create({
      data: { accountId: inbox.accountId, name: name ?? 'Visitor', email },
    })
  }

  const conversation = await db.conversation.create({
    data: { accountId: inbox.accountId, inboxId, contactId: contact.id, status: 'OPEN' },
  })

  return NextResponse.json({ conversationId: conversation.id, contactId: contact.id })
}
