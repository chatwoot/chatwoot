'use client'

import { useEffect, useRef, useState } from 'react'
import { cn } from '@/lib/utils'

interface Message {
  id: string
  content: string
  contentType: string
  authorType: string
  authorId: string | null
  authorEmail: string | null
  private: boolean
  createdAt: Date | string
}

interface MessageThreadProps {
  conversationId: string
  initialMessages: Message[]
  agentId: string
}

export function MessageThread({
  conversationId,
  initialMessages,
  agentId,
}: MessageThreadProps) {
  const [messages, setMessages] = useState<Message[]>(initialMessages)
  const bottomRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const last = messages[messages.length - 1]
    const since = last
      ? new Date(last.createdAt).toISOString()
      : new Date().toISOString()

    const es = new EventSource(
      `/api/conversations/${conversationId}/events?since=${since}`,
    )

    es.onmessage = (e) => {
      const payload = JSON.parse(e.data) as { type: string; data?: Message[] }
      if (payload.type === 'messages' && payload.data?.length) {
        setMessages((prev) => {
          const ids = new Set(prev.map((m) => m.id))
          const next = payload.data!.filter((m) => !ids.has(m.id))
          return next.length ? [...prev, ...next] : prev
        })
      }
    }

    return () => es.close()
  }, [conversationId]) // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  if (messages.length === 0) {
    return (
      <div className="flex flex-1 items-center justify-center text-sm text-slate-400">
        No messages yet. Start the conversation below.
      </div>
    )
  }

  return (
    <div className="flex flex-1 flex-col gap-3 overflow-y-auto p-4">
      {messages.map((msg) => {
        const isAgent = msg.authorType === 'agent'
        const isMine = isAgent && msg.authorId === agentId
        return (
          <div
            key={msg.id}
            className={cn('flex', isMine ? 'justify-end' : 'justify-start')}
          >
            <div
              className={cn(
                'max-w-[70%] rounded-2xl px-4 py-2.5 text-sm leading-relaxed',
                isMine
                  ? 'rounded-br-sm bg-slate-900 text-white'
                  : 'rounded-bl-sm bg-slate-100 text-slate-900',
                msg.private && 'border border-yellow-300 bg-yellow-50 text-slate-700',
              )}
            >
              {msg.private && (
                <span className="mb-1 block text-xs font-medium text-yellow-600">
                  Private note
                </span>
              )}
              {msg.contentType === 'html' ? (
                <div
                  className="prose prose-sm max-w-none"
                  dangerouslySetInnerHTML={{ __html: msg.content }}
                />
              ) : (
                msg.content
              )}
              <div
                className={cn(
                  'mt-1 text-right text-xs opacity-60',
                  isMine ? 'text-slate-300' : 'text-slate-500',
                )}
              >
                {new Date(msg.createdAt).toLocaleTimeString([], {
                  hour: '2-digit',
                  minute: '2-digit',
                })}
              </div>
            </div>
          </div>
        )
      })}
      <div ref={bottomRef} />
    </div>
  )
}
