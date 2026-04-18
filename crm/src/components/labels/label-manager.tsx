'use client'

import { useActionState, useState } from 'react'
import { createLabel, updateLabel, deleteLabel } from '@/app/actions/labels'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Pencil, Trash2, Check, X } from 'lucide-react'

interface LabelRow {
  id: string
  title: string
  color: string
}

interface LabelManagerProps {
  workspace: string
  labels: LabelRow[]
}

function LabelDot({ color }: { color: string }) {
  return (
    <span
      className="inline-block h-3 w-3 shrink-0 rounded-full border border-white/20"
      style={{ backgroundColor: color }}
    />
  )
}

function EditRow({
  label,
  workspace,
  onCancel,
}: {
  label: LabelRow
  workspace: string
  onCancel: () => void
}) {
  const [state, action, pending] = useActionState(updateLabel, undefined)

  return (
    <form action={action} className="flex items-center gap-2">
      <input type="hidden" name="workspace" value={workspace} />
      <input type="hidden" name="id" value={label.id} />
      <input
        type="color"
        name="color"
        defaultValue={label.color}
        className="h-8 w-10 cursor-pointer rounded border border-slate-200 p-0.5"
      />
      <Input name="title" defaultValue={label.title} className="h-8 flex-1" required />
      {state?.error && <span className="text-xs text-red-500">{state.error}</span>}
      <Button size="sm" type="submit" disabled={pending} variant="ghost">
        <Check className="h-3.5 w-3.5" />
      </Button>
      <Button size="sm" type="button" variant="ghost" onClick={onCancel}>
        <X className="h-3.5 w-3.5" />
      </Button>
    </form>
  )
}

export function LabelManager({ workspace, labels }: LabelManagerProps) {
  const [createState, createAction, createPending] = useActionState(createLabel, undefined)
  const [editingId, setEditingId] = useState<string | null>(null)

  return (
    <div className="space-y-6">
      {/* Create form */}
      <div className="rounded-xl border border-slate-200 bg-white p-5">
        <h2 className="mb-4 text-sm font-semibold text-slate-900">New label</h2>
        <form action={createAction} className="flex items-end gap-3">
          <input type="hidden" name="workspace" value={workspace} />
          <div className="space-y-1.5">
            <Label htmlFor="color">Color</Label>
            <input
              id="color"
              type="color"
              name="color"
              defaultValue="#6C7589"
              className="h-10 w-14 cursor-pointer rounded-lg border border-slate-200 p-1"
            />
          </div>
          <div className="flex-1 space-y-1.5">
            <Label htmlFor="title">Title *</Label>
            <Input id="title" name="title" placeholder="e.g. Bug, Feature, Billing…" required />
          </div>
          {createState?.error && (
            <span className="mb-2.5 text-xs text-red-500">{createState.error}</span>
          )}
          <Button type="submit" disabled={createPending} className="mb-0.5">
            {createPending ? 'Adding…' : 'Add label'}
          </Button>
        </form>
      </div>

      {/* Labels list */}
      <div className="rounded-xl border border-slate-200 bg-white overflow-hidden">
        {labels.length === 0 ? (
          <p className="py-10 text-center text-sm text-slate-400">No labels yet.</p>
        ) : (
          <ul className="divide-y divide-slate-100">
            {labels.map((lbl) => (
              <li key={lbl.id} className="px-4 py-3">
                {editingId === lbl.id ? (
                  <EditRow
                    label={lbl}
                    workspace={workspace}
                    onCancel={() => setEditingId(null)}
                  />
                ) : (
                  <div className="flex items-center justify-between gap-3">
                    <div className="flex items-center gap-2.5">
                      <LabelDot color={lbl.color} />
                      <span
                        className="rounded-full px-2.5 py-0.5 text-xs font-medium"
                        style={{ backgroundColor: `${lbl.color}20`, color: lbl.color }}
                      >
                        {lbl.title}
                      </span>
                    </div>
                    <div className="flex items-center gap-1">
                      <Button
                        size="icon"
                        variant="ghost"
                        className="h-7 w-7"
                        onClick={() => setEditingId(lbl.id)}
                      >
                        <Pencil className="h-3.5 w-3.5" />
                      </Button>
                      <form
                        action={async () => {
                          'use server'
                          await deleteLabel(workspace, lbl.id)
                        }}
                      >
                        <Button size="icon" variant="ghost" className="h-7 w-7 text-red-400 hover:text-red-600" type="submit">
                          <Trash2 className="h-3.5 w-3.5" />
                        </Button>
                      </form>
                    </div>
                  </div>
                )}
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  )
}
