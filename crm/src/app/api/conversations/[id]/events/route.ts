import { type NextRequest } from 'next/server'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'

export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const session = await auth()
  if (!session?.user) return new Response('Unauthorized', { status: 401 })

  const { id } = await params
  const sinceParam = req.nextUrl.searchParams.get('since')
  let lastCheck = sinceParam ? new Date(sinceParam) : new Date()

  const encoder = new TextEncoder()

  const stream = new ReadableStream({
    async start(controller) {
      const send = (data: unknown) => {
        controller.enqueue(
          encoder.encode(`data: ${JSON.stringify(data)}\n\n`),
        )
      }

      send({ type: 'connected' })

      const poll = async () => {
        try {
          const messages = await db.message.findMany({
            where: { conversationId: id, createdAt: { gt: lastCheck } },
            orderBy: { createdAt: 'asc' },
          })

          if (messages.length > 0) {
            lastCheck = messages[messages.length - 1].createdAt
            send({ type: 'messages', data: messages })
          }
        } catch {
          // swallow DB errors to keep stream alive
        }
      }

      const interval = setInterval(poll, 2000)

      req.signal.addEventListener('abort', () => {
        clearInterval(interval)
        controller.close()
      })
    },
  })

  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      Connection: 'keep-alive',
    },
  })
}
