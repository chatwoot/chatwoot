'use client'

import { useActionState } from 'react'
import { inviteAgent } from '@/app/actions/agents'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

export function InviteAgentForm({ workspace }: { workspace: string }) {
  const [state, action, pending] = useActionState(inviteAgent, undefined)

  return (
    <div className="rounded-xl border border-slate-200 bg-white p-5">
      <h2 className="mb-4 text-sm font-semibold text-slate-900">Add agent</h2>
      <form action={action} className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <input type="hidden" name="workspace" value={workspace} />

        {state?.error && (
          <p className="col-span-full rounded-lg bg-red-50 px-3 py-2 text-sm text-red-600">
            {state.error}
          </p>
        )}

        <div className="space-y-1.5">
          <Label htmlFor="agentName">Full name</Label>
          <Input id="agentName" name="name" placeholder="Jane Doe" required />
        </div>
        <div className="space-y-1.5">
          <Label htmlFor="agentEmail">Email</Label>
          <Input id="agentEmail" name="email" type="email" placeholder="jane@company.com" required />
        </div>
        <div className="space-y-1.5">
          <Label htmlFor="agentPassword">Temp password</Label>
          <Input id="agentPassword" name="password" type="password" placeholder="min 8 chars" required />
        </div>
        <div className="space-y-1.5">
          <Label htmlFor="agentRole">Role</Label>
          <select
            id="agentRole"
            name="role"
            className="h-10 w-full rounded-lg border border-slate-200 bg-white px-3 text-sm focus:outline-none focus:ring-2 focus:ring-slate-900"
          >
            <option value="AGENT">Agent</option>
            <option value="ADMIN">Admin</option>
          </select>
        </div>

        <div className="col-span-full">
          <Button type="submit" disabled={pending}>
            {pending ? 'Adding…' : 'Add agent'}
          </Button>
        </div>
      </form>
    </div>
  )
}
