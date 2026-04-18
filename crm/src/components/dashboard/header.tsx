'use client'

import { logout } from '@/app/actions/auth'
import { Button } from '@/components/ui/button'
import { LogOut } from 'lucide-react'

export function Header({ userName }: { userName: string }) {
  return (
    <header className="flex h-14 items-center justify-between border-b border-slate-200 bg-white px-4">
      <div />
      <div className="flex items-center gap-3">
        <span className="text-sm text-slate-600">{userName}</span>
        <form action={logout}>
          <Button variant="ghost" size="icon" type="submit" title="Sign out">
            <LogOut className="h-4 w-4" />
          </Button>
        </form>
      </div>
    </header>
  )
}
