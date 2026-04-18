'use client'

import { useActionState, useRef, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { sendMessage } from '@/app/actions/conversations'
import { Button } from '@/components/ui/button'
import { Send, Lock } from 'lucide-react'
import { cn } from '@/lib/utils'

interface ReplyBoxProps {
  workspace: string
  conversationId: string
}

export function ReplyBox({ workspace, conversationId }: ReplyBoxProps) {
  const router = useRouter()
  const textareaRef = useRef<HTMLTextAreaElement>(null)
  const [state, action, pending] = useActionState(sendMessage, undefined)

  useEffect(() => {
    if (!pending && !state?.error) {
      if (textareaRef.current) textareaRef.current.value = ''
      router.refresh()
    }
  }, [pending, state, router])

  return (
    <div className="border-t border-slate-200 bg-white p-4">
      {state?.error && (
        <p className="mb-2 rounded-lg bg-red-50 px-3 py-1.5 text-xs text-red-600">
          {state.error}
        </p>
      )}
      <form action={action} className="space-y-2">
        <input type="hidden" name="workspace" value={workspace} />
        <input type="hidden" name="conversationId" value={conversationId} />

        <textarea
          ref={textareaRef}
          name="content"
          rows={3}
          placeholder="Type a reply… (Shift+Enter for new line)"
          className="w-full resize-none rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm placeholder:text-slate-400 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-900"
          onKeyDown={(e) => {
            if (e.key === 'Enter' && !e.shiftKey) {
              e.preventDefault()
              e.currentTarget.form?.requestSubmit()
            }
          }}
        />

        <div className="flex items-center justify-between">
          <label className="flex cursor-pointer items-center gap-1.5 text-xs text-slate-500">
            <input type="checkbox" name="private" value="true" className="rounded" />
            <Lock className="h-3 w-3" />
            Private note
          </label>
          <Button type="submit" size="sm" disabled={pending}>
            <Send className="mr-1.5 h-3.5 w-3.5" />
            {pending ? 'Sending…' : 'Send'}
          </Button>
        </div>
      </form>
    </div>
  )
}
