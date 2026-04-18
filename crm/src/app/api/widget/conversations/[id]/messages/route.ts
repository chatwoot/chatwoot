import { NextRequest, NextResponse } from 'next/server'
import { db } from '@/lib/db'

export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const { id } = await params
  const since = req.nextUrl.searchParams.get('since')

  const messages = await db.message.findMany({
    where: {
      conversationId: id,
      private: false,
      ...(since && { createdAt: { gt: new Date(since) } }),
    },
    orderBy: { createdAt: 'asc' },
  })

  return NextResponse.json(messages)
}

export async function POST(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const { id } = await params
  const body = await req.json()
  const { content, contactId } = body as { content: string; contactId: string }

  if (!content?.trim()) {
    return NextResponse.json({ error: 'Content required' }, { status: 400 })
  }

  const conversation = await db.conversation.findUnique({ where: { id } })
  if (!conversation) {
    return NextResponse.json({ error: 'Conversation not found' }, { status: 404 })
  }

  const message = await db.message.create({
    data: {
      conversationId: id,
      content: content.trim(),
      authorType: 'contact',
      authorId: contactId,
    },
  })

  await db.conversation.update({ where: { id }, data: { updatedAt: new Date() } })

  return NextResponse.json(message)
}
