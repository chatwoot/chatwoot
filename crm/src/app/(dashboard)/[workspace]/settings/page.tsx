import Link from 'next/link'
import { Users, Tag, Inbox, Zap, Webhook, CreditCard } from 'lucide-react'

const sections = [
  { href: 'agents', label: 'Agents & Roles', desc: 'Manage team members and permissions', icon: Users },
  { href: '../labels', label: 'Labels', desc: 'Color-coded conversation tags', icon: Tag },
  { href: '../inboxes', label: 'Inboxes', desc: 'Configure channels and integrations', icon: Inbox },
  { href: '../automations', label: 'Automations', desc: 'Auto-assign and auto-reply rules', icon: Zap },
  { href: 'webhooks', label: 'Webhooks', desc: 'Subscribe to events for your integrations', icon: Webhook },
  { href: 'billing', label: 'Billing', desc: 'Manage your subscription and plan', icon: CreditCard },
]

export default async function SettingsPage({
  params,
}: {
  params: Promise<{ workspace: string }>
}) {
  const { workspace: slug } = await params

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-2xl font-semibold text-slate-900">Settings</h1>
        <p className="text-sm text-slate-500">Configure your workspace</p>
      </div>
      <div className="grid gap-3 sm:grid-cols-2">
        {sections.map(({ href, label, desc, icon: Icon }) => (
          <Link
            key={href}
            href={`/${slug}/settings/${href}`}
            className="flex items-start gap-4 rounded-xl border border-slate-200 bg-white p-5 hover:bg-slate-50 transition-colors"
          >
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-slate-100">
              <Icon className="h-5 w-5 text-slate-500" />
            </div>
            <div>
              <p className="text-sm font-semibold text-slate-900">{label}</p>
              <p className="text-xs text-slate-400">{desc}</p>
            </div>
          </Link>
        ))}
      </div>
    </div>
  )
}
