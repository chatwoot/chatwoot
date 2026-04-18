'use client'

import { useEffect, useRef, useState } from 'react'
import { Send } from 'lucide-react'

interface Message {
  id: string
  content: string
  authorType: string
  createdAt: string
}

export default function WidgetPage({ params }: { params: Promise<{ inboxId: string }> }) {
  const [inboxId, setInboxId] = useState<string>('')
  const [conversationId, setConversationId] = useState<string | null>(null)
  const [contactId, setContactId] = useState<string | null>(null)
  const [messages, setMessages] = useState<Message[]>([])
  const [input, setInput] = useState('')
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [started, setStarted] = useState(false)
  const [sending, setSending] = useState(false)
  const bottomRef = useRef<HTMLDivElement>(null)
  const pollRef = useRef<ReturnType<typeof setInterval>>(null)

  useEffect(() => {
    params.then((p) => setInboxId(p.inboxId))
  }, [params])

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  useEffect(() => {
    if (!conversationId) return

    const poll = async () => {
      const lastCreatedAt = messages[messages.length - 1]?.createdAt
      const url = `/api/widget/conversations/${conversationId}/messages${lastCreatedAt ? `?since=${lastCreatedAt}` : ''}`
      const res = await fetch(url)
      if (!res.ok) return
      const data: Message[] = await res.json()
      if (data.length) {
        setMessages((prev) => {
          const ids = new Set(prev.map((m) => m.id))
          return [...prev, ...data.filter((m) => !ids.has(m.id))]
        })
      }
    }

    pollRef.current = setInterval(poll, 3000)
    return () => {
      if (pollRef.current) clearInterval(pollRef.current)
    }
  }, [conversationId, messages])

  const startConversation = async () => {
    if (!name.trim()) return
    const res = await fetch(`/api/widget/${inboxId}/conversations`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: name.trim(), email: email.trim() || undefined }),
    })
    if (!res.ok) return
    const data = await res.json()
    setConversationId(data.conversationId)
    setContactId(data.contactId)
    setStarted(true)
  }

  const handleSend = async () => {
    if (!input.trim() || !conversationId || !contactId) return
    setSending(true)
    const content = input.trim()
    setInput('')

    const res = await fetch(`/api/widget/conversations/${conversationId}/messages`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ content, contactId }),
    })
    if (res.ok) {
      const msg: Message = await res.json()
      setMessages((prev) => [...prev, msg])
    }
    setSending(false)
  }

  return (
    <div className="flex h-screen flex-col bg-white font-sans text-sm">
      {/* Header */}
      <div className="bg-slate-900 px-4 py-3 text-white">
        <h1 className="font-semibold">Support Chat</h1>
        <p className="text-xs text-slate-400">We typically reply within minutes</p>
      </div>

      {!started ? (
        <div className="flex flex-1 flex-col justify-center gap-3 p-5">
          <p className="text-slate-600">Tell us a bit about yourself to get started.</p>
          <input
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Your name *"
            className="h-10 rounded-lg border border-slate-200 px-3 text-sm focus:outline-none focus:ring-2 focus:ring-slate-900"
          />
          <input
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="Email (optional)"
            type="email"
            className="h-10 rounded-lg border border-slate-200 px-3 text-sm focus:outline-none focus:ring-2 focus:ring-slate-900"
          />
          <button
            onClick={startConversation}
            disabled={!name.trim()}
            className="h-10 rounded-lg bg-slate-900 text-sm font-medium text-white transition hover:bg-slate-800 disabled:opacity-50"
          >
            Start chat
          </button>
        </div>
      ) : (
        <>
          <div className="flex flex-1 flex-col gap-2 overflow-y-auto p-3">
            {messages.length === 0 && (
              <p className="mt-4 text-center text-xs text-slate-400">
                Send a message to get started.
              </p>
            )}
            {messages.map((msg) => (
              <div
                key={msg.id}
                className={`flex ${msg.authorType === 'contact' ? 'justify-end' : 'justify-start'}`}
              >
                <div
                  className={`max-w-[80%] rounded-2xl px-3 py-2 text-sm leading-relaxed ${
                    msg.authorType === 'contact'
                      ? 'rounded-br-sm bg-slate-900 text-white'
                      : 'rounded-bl-sm bg-slate-100 text-slate-900'
                  }`}
                >
                  {msg.content}
                </div>
              </div>
            ))}
            <div ref={bottomRef} />
          </div>

          <div className="flex items-end gap-2 border-t border-slate-200 p-3">
            <textarea
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter' && !e.shiftKey) {
                  e.preventDefault()
                  handleSend()
                }
              }}
              rows={1}
              placeholder="Type a message…"
              className="flex-1 resize-none rounded-lg border border-slate-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-slate-900"
            />
            <button
              onClick={handleSend}
              disabled={!input.trim() || sending}
              className="flex h-9 w-9 items-center justify-center rounded-lg bg-slate-900 text-white transition hover:bg-slate-800 disabled:opacity-50"
            >
              <Send className="h-4 w-4" />
            </button>
          </div>
        </>
      )}
    </div>
  )
}
