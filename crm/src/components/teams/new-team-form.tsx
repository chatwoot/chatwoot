'use client'

import { useActionState } from 'react'
import { createTeam } from '@/app/actions/teams'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

export function NewTeamForm({ workspace }: { workspace: string }) {
  const [state, action, pending] = useActionState(createTeam, undefined)

  return (
    <div className="rounded-xl border border-slate-200 bg-white p-5">
      <h2 className="mb-4 text-sm font-semibold text-slate-900">New team</h2>
      <form action={action} className="flex items-end gap-3 max-w-sm">
        <input type="hidden" name="workspace" value={workspace} />
        <div className="flex-1 space-y-1.5">
          <Label htmlFor="teamName">Team name</Label>
          <Input id="teamName" name="name" placeholder="e.g. Support, Sales…" required />
        </div>
        {state?.error && (
          <span className="mb-2.5 text-xs text-red-500">{state.error}</span>
        )}
        <Button type="submit" disabled={pending} className="mb-0.5">
          {pending ? 'Creating…' : 'Create'}
        </Button>
      </form>
    </div>
  )
}
