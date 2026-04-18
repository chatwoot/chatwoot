'use client'

import { useActionState } from 'react'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

type ContactFormAction = (
  prev: { error: string } | undefined,
  formData: FormData,
) => Promise<{ error: string } | undefined>

interface ContactFormProps {
  action: ContactFormAction
  workspace: string
  defaultValues?: {
    id?: string
    name?: string
    email?: string
    phone?: string
    company?: string
  }
}

export function ContactForm({ action, workspace, defaultValues }: ContactFormProps) {
  const [state, formAction, pending] = useActionState(action, undefined)

  return (
    <form action={formAction} className="space-y-5 max-w-lg">
      <input type="hidden" name="workspace" value={workspace} />
      {defaultValues?.id && <input type="hidden" name="id" value={defaultValues.id} />}

      {state?.error && (
        <p className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-600">{state.error}</p>
      )}

      <div className="space-y-1.5">
        <Label htmlFor="name">Full name *</Label>
        <Input
          id="name"
          name="name"
          placeholder="Jane Doe"
          defaultValue={defaultValues?.name}
          required
        />
      </div>
      <div className="space-y-1.5">
        <Label htmlFor="email">Email</Label>
        <Input
          id="email"
          name="email"
          type="email"
          placeholder="jane@company.com"
          defaultValue={defaultValues?.email}
        />
      </div>
      <div className="space-y-1.5">
        <Label htmlFor="phone">Phone</Label>
        <Input
          id="phone"
          name="phone"
          type="tel"
          placeholder="+1 555 000 0000"
          defaultValue={defaultValues?.phone}
        />
      </div>
      <div className="space-y-1.5">
        <Label htmlFor="company">Company</Label>
        <Input
          id="company"
          name="company"
          placeholder="Acme Inc."
          defaultValue={defaultValues?.company}
        />
      </div>

      <div className="flex gap-3 pt-1">
        <Button type="submit" disabled={pending}>
          {pending ? 'Saving…' : defaultValues?.id ? 'Save changes' : 'Create contact'}
        </Button>
        <Button variant="outline" asChild>
          <Link href={`/${workspace}/contacts`}>Cancel</Link>
        </Button>
      </div>
    </form>
  )
}
