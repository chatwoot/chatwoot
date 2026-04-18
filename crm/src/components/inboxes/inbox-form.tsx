'use client'

import { useActionState, useState } from 'react'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

type InboxAction = (
  prev: { error: string } | undefined,
  formData: FormData,
) => Promise<{ error: string } | undefined>

interface InboxFormProps {
  action: InboxAction
  workspace: string
  defaultValues?: {
    id?: string
    name?: string
    channelType?: string
    email?: string
    emailFromName?: string
    widgetColor?: string
  }
}

export function InboxForm({ action, workspace, defaultValues }: InboxFormProps) {
  const [state, formAction, pending] = useActionState(action, undefined)
  const [channelType, setChannelType] = useState(defaultValues?.channelType ?? 'LIVE_CHAT')
  const isEdit = !!defaultValues?.id

  return (
    <form action={formAction} className="max-w-lg space-y-5">
      <input type="hidden" name="workspace" value={workspace} />
      {defaultValues?.id && <input type="hidden" name="id" value={defaultValues.id} />}

      {state?.error && (
        <p className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-600">{state.error}</p>
      )}

      <div className="space-y-1.5">
        <Label htmlFor="name">Inbox name *</Label>
        <Input id="name" name="name" placeholder="Support" defaultValue={defaultValues?.name} required />
      </div>

      {!isEdit && (
        <div className="space-y-1.5">
          <Label htmlFor="channelType">Channel type</Label>
          <select
            id="channelType"
            name="channelType"
            value={channelType}
            onChange={(e) => setChannelType(e.target.value)}
            className="h-10 w-full rounded-lg border border-slate-200 bg-white px-3 text-sm focus:outline-none focus:ring-2 focus:ring-slate-900"
          >
            <option value="LIVE_CHAT">Live Chat</option>
            <option value="EMAIL">Email</option>
            <option value="API">API</option>
          </select>
        </div>
      )}

      {channelType === 'EMAIL' && (
        <>
          <div className="space-y-1.5">
            <Label htmlFor="email">Inbox email address</Label>
            <Input
              id="email"
              name="email"
              type="email"
              placeholder="support@yourcompany.com"
              defaultValue={defaultValues?.email}
            />
            <p className="text-xs text-slate-400">
              Emails sent to this address will create conversations.
            </p>
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="emailFromName">From name</Label>
            <Input
              id="emailFromName"
              name="emailFromName"
              placeholder="Acme Support"
              defaultValue={defaultValues?.emailFromName}
            />
          </div>
        </>
      )}

      {channelType === 'LIVE_CHAT' && (
        <div className="space-y-1.5">
          <Label htmlFor="widgetColor">Widget color</Label>
          <div className="flex items-center gap-3">
            <input
              id="widgetColor"
              name="widgetColor"
              type="color"
              defaultValue={defaultValues?.widgetColor ?? '#1F93FF'}
              className="h-10 w-16 cursor-pointer rounded-lg border border-slate-200 p-1"
            />
            <span className="text-xs text-slate-400">Color of the chat widget button</span>
          </div>
        </div>
      )}

      <div className="flex gap-3">
        <Button type="submit" disabled={pending}>
          {pending ? 'Saving…' : isEdit ? 'Save changes' : 'Create inbox'}
        </Button>
        <Button variant="outline" asChild>
          <Link href={`/${workspace}/inboxes`}>Cancel</Link>
        </Button>
      </div>
    </form>
  )
}
