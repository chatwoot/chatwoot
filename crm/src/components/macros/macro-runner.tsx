'use client'

import { useState, useTransition } from 'react'
import { runMacro } from '@/app/actions/macros'
import { Button } from '@/components/ui/button'
import { Play } from 'lucide-react'

interface Props {
  workspace: string
  conversationId: string
  macros: { id: string; name: string }[]
}

export function MacroRunner({ workspace, conversationId, macros }: Props) {
  const [selectedId, setSelectedId] = useState('')
  const [isPending, startTransition] = useTransition()

  if (!macros.length) return null

  function run() {
    if (!selectedId) return
    startTransition(() => runMacro(workspace, conversationId, selectedId))
  }

  return (
    <div className="flex items-center gap-1.5">
      <Play className="h-4 w-4 shrink-0 text-slate-400" />
      <select
        value={selectedId}
        onChange={(e) => setSelectedId(e.target.value)}
        className="h-8 rounded-lg border border-slate-200 bg-white px-2 text-xs text-slate-600 focus:outline-none"
      >
        <option value="">Run macro…</option>
        {macros.map((m) => (
          <option key={m.id} value={m.id}>
            {m.name}
          </option>
        ))}
      </select>
      {selectedId && (
        <Button size="sm" variant="outline" onClick={run} disabled={isPending}>
          {isPending ? '…' : 'Run'}
        </Button>
      )}
    </div>
  )
}
