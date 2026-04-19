'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Plus, X } from 'lucide-react'

const EVENTS = [
  { value: 'conversation_created', label: 'Conversation created' },
  { value: 'conversation_updated', label: 'Conversation updated' },
  { value: 'message_created', label: 'Message received' },
]

const CONDITION_ATTRIBUTES = [
  { value: 'status', label: 'Status' },
  { value: 'inbox_id', label: 'Inbox' },
  { value: 'assignee_id', label: 'Assignee' },
  { value: 'label', label: 'Label' },
  { value: 'contact_email', label: 'Contact email' },
]

const CONDITION_OPERATORS = [
  { value: 'equals', label: 'Equals' },
  { value: 'not_equals', label: 'Does not equal' },
  { value: 'contains', label: 'Contains' },
  { value: 'not_contains', label: 'Does not contain' },
  { value: 'is_present', label: 'Is present' },
  { value: 'is_not_present', label: 'Is not present' },
]

const ACTION_TYPES = [
  { value: 'assign_agent', label: 'Assign to agent' },
  { value: 'add_label', label: 'Add label' },
  { value: 'remove_label', label: 'Remove label' },
  { value: 'update_status', label: 'Update status' },
  { value: 'send_message', label: 'Send message' },
  { value: 'send_webhook', label: 'Send webhook' },
]

interface Condition {
  attribute: string
  operator: string
  value: string
}

interface AutomationAction {
  type: string
  params: Record<string, string>
}

interface Props {
  action: (formData: FormData) => void | Promise<void>
  initial?: {
    name: string
    event: string
    conditions: Condition[]
    actions: AutomationAction[]
  }
  agents: { id: string; name: string | null; email: string }[]
  labels: { id: string; title: string }[]
  inboxes: { id: string; name: string }[]
}

const selectCls =
  'h-8 rounded-lg border border-slate-200 bg-white px-2 text-xs text-slate-700 focus:outline-none'

export function AutomationForm({ action, initial, agents, labels, inboxes }: Props) {
  const [conditions, setConditions] = useState<Condition[]>(initial?.conditions ?? [])
  const [actions, setActions] = useState<AutomationAction[]>(initial?.actions ?? [])

  function addCondition() {
    setConditions([...conditions, { attribute: 'status', operator: 'equals', value: 'OPEN' }])
  }
  function removeCondition(i: number) {
    setConditions(conditions.filter((_, j) => j !== i))
  }
  function updateCondition(i: number, field: keyof Condition, val: string) {
    setConditions(conditions.map((c, j) => (j === i ? { ...c, [field]: val } : c)))
  }

  function addAction() {
    setActions([...actions, { type: 'update_status', params: { status: 'RESOLVED' } }])
  }
  function removeAction(i: number) {
    setActions(actions.filter((_, j) => j !== i))
  }
  function updateActionType(i: number, type: string) {
    setActions(actions.map((a, j) => (j === i ? { type, params: defaultParams(type) } : a)))
  }
  function updateActionParam(i: number, key: string, val: string) {
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

  function conditionValueWidget(c: Condition, i: number) {
    if (['is_present', 'is_not_present'].includes(c.operator)) return null
    switch (c.attribute) {
      case 'status':
        return (
          <select
            value={c.value}
            onChange={(e) => updateCondition(i, 'value', e.target.value)}
            className={selectCls}
          >
            {['OPEN', 'RESOLVED', 'PENDING', 'SNOOZED'].map((s) => (
              <option key={s} value={s}>
                {s}
              </option>
            ))}
          </select>
        )
      case 'inbox_id':
        return (
          <select
            value={c.value}
            onChange={(e) => updateCondition(i, 'value', e.target.value)}
            className={selectCls}
          >
            {inboxes.map((b) => (
              <option key={b.id} value={b.id}>
                {b.name}
              </option>
            ))}
          </select>
        )
      case 'assignee_id':
        return (
          <select
            value={c.value}
            onChange={(e) => updateCondition(i, 'value', e.target.value)}
            className={selectCls}
          >
            {agents.map((a) => (
              <option key={a.id} value={a.id}>
                {a.name ?? a.email}
              </option>
            ))}
          </select>
        )
      case 'label':
        return (
          <select
            value={c.value}
            onChange={(e) => updateCondition(i, 'value', e.target.value)}
            className={selectCls}
          >
            {labels.map((l) => (
              <option key={l.id} value={l.title}>
                {l.title}
              </option>
            ))}
          </select>
        )
      default:
        return (
          <input
            type="text"
            value={c.value}
            onChange={(e) => updateCondition(i, 'value', e.target.value)}
            placeholder="Value"
            className="h-8 w-32 rounded-lg border border-slate-200 bg-white px-2 text-xs text-slate-700 focus:outline-none"
          />
        )
    }
  }

  function actionParamsWidget(a: AutomationAction, i: number) {
    switch (a.type) {
      case 'assign_agent':
        return (
          <select
            value={a.params.agentId ?? ''}
            onChange={(e) => updateActionParam(i, 'agentId', e.target.value)}
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
            onChange={(e) => updateActionParam(i, 'labelId', e.target.value)}
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
            onChange={(e) => updateActionParam(i, 'status', e.target.value)}
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
            onChange={(e) => updateActionParam(i, 'content', e.target.value)}
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
            onChange={(e) => updateActionParam(i, 'url', e.target.value)}
            placeholder="https://…"
            className="h-8 w-full rounded-lg border border-slate-200 bg-white px-2 text-xs text-slate-700 focus:outline-none"
          />
        )
      default:
        return null
    }
  }

  return (
    <form action={action} className="space-y-6">
      <input type="hidden" name="conditions" value={JSON.stringify(conditions)} readOnly />
      <input type="hidden" name="actions" value={JSON.stringify(actions)} readOnly />

      <div className="space-y-1.5">
        <Label htmlFor="name">Name</Label>
        <Input
          id="name"
          name="name"
          defaultValue={initial?.name}
          required
          placeholder="e.g. Auto-resolve spam"
        />
      </div>

      <div className="space-y-1.5">
        <Label htmlFor="event">Trigger event</Label>
        <select
          id="event"
          name="event"
          defaultValue={initial?.event ?? 'conversation_created'}
          className="h-9 w-full rounded-lg border border-slate-200 bg-white px-3 text-sm text-slate-700 focus:outline-none"
        >
          {EVENTS.map((e) => (
            <option key={e.value} value={e.value}>
              {e.label}
            </option>
          ))}
        </select>
      </div>

      {/* Conditions */}
      <div className="space-y-2">
        <div className="flex items-center justify-between">
          <Label>Conditions</Label>
          <Button type="button" variant="outline" size="sm" onClick={addCondition}>
            <Plus className="mr-1 h-3 w-3" />
            Add
          </Button>
        </div>
        {conditions.length === 0 ? (
          <p className="text-xs text-slate-400">No conditions — always triggers on the event.</p>
        ) : (
          conditions.map((c, i) => (
            <div
              key={i}
              className="flex flex-wrap items-center gap-2 rounded-lg border border-slate-100 bg-slate-50 p-2"
            >
              <select
                value={c.attribute}
                onChange={(e) => updateCondition(i, 'attribute', e.target.value)}
                className={selectCls}
              >
                {CONDITION_ATTRIBUTES.map((a) => (
                  <option key={a.value} value={a.value}>
                    {a.label}
                  </option>
                ))}
              </select>
              <select
                value={c.operator}
                onChange={(e) => updateCondition(i, 'operator', e.target.value)}
                className={selectCls}
              >
                {CONDITION_OPERATORS.map((o) => (
                  <option key={o.value} value={o.value}>
                    {o.label}
                  </option>
                ))}
              </select>
              {conditionValueWidget(c, i)}
              <button
                type="button"
                onClick={() => removeCondition(i)}
                className="ml-auto text-slate-400 hover:text-red-500"
              >
                <X className="h-3.5 w-3.5" />
              </button>
            </div>
          ))
        )}
      </div>

      {/* Actions */}
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
                onChange={(e) => updateActionType(i, e.target.value)}
                className={`${selectCls} shrink-0`}
              >
                {ACTION_TYPES.map((t) => (
                  <option key={t.value} value={t.value}>
                    {t.label}
                  </option>
                ))}
              </select>
              <div className="min-w-0 flex-1">{actionParamsWidget(a, i)}</div>
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

      <Button type="submit">Save automation</Button>
    </form>
  )
}
