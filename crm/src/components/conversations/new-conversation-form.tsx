'use client'

import { useActionState } from 'react'
import Link from 'next/link'
import { createConversation } from '@/app/actions/conversations'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { Input } from '@/components/ui/input'

interface Props {
  workspace: string
  inboxes: { id: string; name: string }[]
  contacts: { id: string; name: string; email: string | null }[]
}

export function NewConversationForm({ workspace, inboxes, contacts }: Props) {
  const [state, action, pending] = useActionState(createConversation, undefined)

  return (
    <form action={action} className="max-w-lg space-y-4">
      <input type="hidden" name="workspace" value={workspace} />

      {state?.error && (
        <p className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-600">{state.error}</p>
      )}

      <div className="space-y-1.5">
        <Label htmlFor="inboxId">Inbox *</Label>
        <select
          id="inboxId"
          name="inboxId"
          required
          className="h-10 w-full rounded-lg border border-slate-200 bg-white px-3 text-sm focus:outline-none focus:ring-2 focus:ring-slate-900"
        >
          {inboxes.map((inbox) => (
            <option key={inbox.id} value={inbox.id}>
              {inbox.name}
            </option>
          ))}
        </select>
      </div>

      <div className="space-y-1.5">
        <Label htmlFor="contactId">Contact</Label>
        <select
          id="contactId"
          name="contactId"
          className="h-10 w-full rounded-lg border border-slate-200 bg-white px-3 text-sm focus:outline-none focus:ring-2 focus:ring-slate-900"
        >
          <option value="">No contact (anonymous)</option>
          {contacts.map((c) => (
            <option key={c.id} value={c.id}>
              {c.name} {c.email ? `(${c.email})` : ''}
            </option>
          ))}
        </select>
      </div>

      <div className="space-y-1.5">
        <Label htmlFor="subject">Subject (optional)</Label>
        <Input id="subject" name="subject" placeholder="Re: Support request" />
      </div>

      <div className="flex gap-3">
        <Button type="submit" disabled={pending}>
          {pending ? 'Creating…' : 'Create conversation'}
        </Button>
        <Button variant="outline" asChild>
          <Link href={`/${workspace}/conversations`}>Cancel</Link>
        </Button>
      </div>
    </form>
  )
}
