'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { cn } from '@/lib/utils'
import {
  MessageSquare,
  Users,
  Inbox,
  BarChart2,
  Settings,
  Tag,
  Zap,
  Play,
} from 'lucide-react'

const navItems = [
  { href: 'conversations', label: 'Conversations', icon: MessageSquare },
  { href: 'contacts', label: 'Contacts', icon: Users },
  { href: 'inboxes', label: 'Inboxes', icon: Inbox },
  { href: 'labels', label: 'Labels', icon: Tag },
  { href: 'teams', label: 'Teams', icon: Users },
  { href: 'automations', label: 'Automations', icon: Zap },
  { href: 'macros', label: 'Macros', icon: Play },
  { href: 'reports', label: 'Reports', icon: BarChart2 },
  { href: 'settings', label: 'Settings', icon: Settings },
]

export function Sidebar({ workspace }: { workspace: string }) {
  const pathname = usePathname()

  return (
    <aside className="flex h-full w-60 flex-col border-r border-slate-200 bg-white">
      <div className="flex h-14 items-center border-b border-slate-200 px-4">
        <span className="text-sm font-semibold text-slate-900 truncate">{workspace}</span>
      </div>
      <nav className="flex flex-1 flex-col gap-0.5 p-2">
        {navItems.map(({ href, label, icon: Icon }) => {
          const fullPath = `/${workspace}/${href}`
          const isActive = pathname.startsWith(fullPath)
          return (
            <Link
              key={href}
              href={fullPath}
              className={cn(
                'flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors',
                isActive
                  ? 'bg-slate-100 text-slate-900'
                  : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900',
              )}
            >
              <Icon className="h-4 w-4 shrink-0" />
              {label}
            </Link>
          )
        })}
      </nav>
    </aside>
  )
}
