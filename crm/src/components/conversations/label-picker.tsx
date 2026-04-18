'use client'

import { useState, useTransition } from 'react'
import { toggleConversationLabel } from '@/app/actions/labels'
import { Tag, X } from 'lucide-react'

interface LabelOption {
  id: string
  title: string
  color: string
}

interface LabelPickerProps {
  workspace: string
  conversationId: string
  allLabels: LabelOption[]
  currentLabelIds: string[]
}

export function LabelPicker({
  workspace,
  conversationId,
  allLabels,
  currentLabelIds,
}: LabelPickerProps) {
  const [open, setOpen] = useState(false)
  const [pending, startTransition] = useTransition()

  const assigned = allLabels.filter((l) => currentLabelIds.includes(l.id))
  const available = allLabels.filter((l) => !currentLabelIds.includes(l.id))

  const toggle = (labelId: string) => {
    startTransition(() => {
      toggleConversationLabel(workspace, conversationId, labelId)
    })
  }

  return (
    <div className="space-y-1.5">
      <div className="flex items-center justify-between">
        <span className="text-xs font-medium text-slate-500 uppercase tracking-wide">Labels</span>
        {allLabels.length > 0 && (
          <button
            onClick={() => setOpen((o) => !o)}
            className="text-slate-400 hover:text-slate-700 transition-colors"
            title="Add label"
          >
            <Tag className="h-3.5 w-3.5" />
          </button>
        )}
      </div>

      {/* Assigned labels */}
      <div className="flex flex-wrap gap-1.5">
        {assigned.map((lbl) => (
          <button
            key={lbl.id}
            onClick={() => toggle(lbl.id)}
            disabled={pending}
            className="inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-medium transition-opacity disabled:opacity-50"
            style={{ backgroundColor: `${lbl.color}20`, color: lbl.color }}
          >
            {lbl.title}
            <X className="h-3 w-3" />
          </button>
        ))}
        {assigned.length === 0 && (
          <span className="text-xs text-slate-400">No labels</span>
        )}
      </div>

      {/* Dropdown to add */}
      {open && available.length > 0 && (
        <div className="rounded-lg border border-slate-200 bg-white shadow-lg z-10 overflow-hidden">
          {available.map((lbl) => (
            <button
              key={lbl.id}
              onClick={() => {
                toggle(lbl.id)
                setOpen(false)
              }}
              disabled={pending}
              className="flex w-full items-center gap-2 px-3 py-2 text-left text-sm hover:bg-slate-50 disabled:opacity-50"
            >
              <span
                className="h-2.5 w-2.5 rounded-full shrink-0"
                style={{ backgroundColor: lbl.color }}
              />
              {lbl.title}
            </button>
          ))}
        </div>
      )}
    </div>
  )
}
