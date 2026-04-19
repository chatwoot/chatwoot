'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Plus, X } from 'lucide-react'

const ACTION_TYPES = [
  { value: 'assign_agent', label: 'Assign to agent' },
  { value: 'add_label', label: 'Add label' },
  { value: 'remove_label', label: 'Remove label' },
  { value: 'update_status', label: 'Update status' },
  { value: 'send_message', label: 'Send message' },
  { value: 'send_webhook', label: 'Send webhook' },
]

interface MacroAction {
  type: string
  params: Record<string, string>
}

interface Props {
  action: (formData: FormData) => void | Promise<void>
  initial?: { name: string; actions: MacroAction[] }
  agents: { id: string; name: string | null; email: string }[]
  labels: { id: string; title: string }[]
  workspace: string
  macroId?: string
}

const selectCls =
  'h-8 rounded-lg border border-slate-200 bg-white px-2 text-xs text-slate-700 focus:outline-none'

export function MacroForm({ action, initial, agents, labels, workspace, macroId }: Props) {
  const [actions, setActions] = useState<MacroAction[]>(initial?.actions ?? [])

  function addAction() {
    setActions([...actions, { type: 'update_status', params: { status: 'RESOLVED' } }])
  }
  function removeAction(i: number) {
    setActions(actions.filter((_, j) => j !== i))
  }
  function updateType(i: number, type: string) {
    setActions(actions.map((a, j) => (j === i ? { type, params: defaultParams(type) } : a)))
  }
  function updateParam(i: number, key: string, val: string) {
    setActions(
      actions.map((a, j) => (j === i ? { ...a, params: { ...a.params, [key]: val } } : a)),
    )
  }

  function defaultParams(type: string): Record<string, string> {
    switch (type) {
      case 'assign_agent':
        return { agentId: agents[0]?.id ?? '' }
      case 'add_label':
      case 'remove_label':
        return { labelId: labels[0]?.id ?? '' }
      case 'update_status':
        return { status: 'RESOLVED' }
      case 'send_message':
        return { content: '' }
      case 'send_webhook':
        return { url: '' }
      default:
        return {}
    }
  }

  function paramsWidget(a: MacroAction, i: number) {
    switch (a.type) {
      case 'assign_agent':
        return (
          <select
            value={a.params.agentId ?? ''}
            onChange={(e) => updateParam(i, 'agentId', e.target.value)}
            className={selectCls}
          >
            {agents.map((ag) => (
              <option key={ag.id} value={ag.id}>
                {ag.name ?? ag.email}
              </option>
            ))}
          </select>
        )
      case 'add_label':
      case 'remove_label':
        return (
          <select
            value={a.params.labelId ?? ''}
            onChange={(e) => updateParam(i, 'labelId', e.target.value)}
            className={selectCls}
          >
            {labels.map((l) => (
              <option key={l.id} value={l.id}>
                {l.title}
              </option>
            ))}
          </select>
        )
      case 'update_status':
        return (
          <select
            value={a.params.status ?? 'RESOLVED'}
            onChange={(e) => updateParam(i, 'status', e.target.value)}
            className={selectCls}
          >
            {['OPEN', 'RESOLVED', 'PENDING', 'SNOOZED'].map((s) => (
              <option key={s} value={s}>
                {s}
              </option>
            ))}
          </select>
        )
      case 'send_message':
        return (
          <textarea
            value={a.params.content ?? ''}
            onChange={(e) => updateParam(i, 'content', e.target.value)}
            placeholder="Message content…"
            rows={2}
            className="w-full resize-none rounded-lg border border-slate-200 bg-white px-2 py-1 text-xs text-slate-700 focus:outline-none"
          />
        )
      case 'send_webhook':
        return (
          <input
            type="url"
            value={a.params.url ?? ''}
            onChange={(e) => updateParam(i, 'url', e.target.value)}
            placeholder="https://…"
            className="h-8 w-full rounded-lg border border-slate-200 bg-white px-2 text-xs text-slate-700 focus:outline-none"
          />
        )
      default:
        return null
    }
  }

  return (
    <form action={action} className="space-y-5">
      <input type="hidden" name="workspace" value={workspace} readOnly />
      {macroId && <input type="hidden" name="id" value={macroId} readOnly />}
      <input type="hidden" name="actions" value={JSON.stringify(actions)} readOnly />

      <div className="space-y-1.5">
        <Label htmlFor="name">Name</Label>
        <Input
          id="name"
          name="name"
          defaultValue={initial?.name}
          required
          placeholder="e.g. Close and label spam"
        />
      </div>

      <div className="space-y-2">
        <div className="flex items-center justify-between">
          <Label>Actions</Label>
          <Button type="button" variant="outline" size="sm" onClick={addAction}>
            <Plus className="mr-1 h-3 w-3" />
            Add
          </Button>
        </div>
        {actions.length === 0 ? (
          <p className="text-xs text-slate-400">Add at least one action.</p>
        ) : (
          actions.map((a, i) => (
            <div
              key={i}
              className="flex flex-wrap items-start gap-2 rounded-lg border border-slate-100 bg-slate-50 p-2"
            >
              <select
                value={a.type}
                onChange={(e) => updateType(i, e.target.value)}
                className={`${selectCls} shrink-0`}
              >
                {ACTION_TYPES.map((t) => (
                  <option key={t.value} value={t.value}>
                    {t.label}
                  </option>
                ))}
              </select>
              <div className="min-w-0 flex-1">{paramsWidget(a, i)}</div>
              <button
                type="button"
                onClick={() => removeAction(i)}
                className="text-slate-400 hover:text-red-500"
              >
                <X className="h-3.5 w-3.5" />
              </button>
            </div>
          ))
        )}
      </div>

      <Button type="submit">Save macro</Button>
    </form>
  )
}
