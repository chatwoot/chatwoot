'use client'

import { useRouter, usePathname } from 'next/navigation'
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts'
import type { ReportData } from '@/lib/reports'

interface Props {
  data: ReportData
  workspace: string
}

const PERIOD_LABELS = { '7d': '7 days', '30d': '30 days', '90d': '90 days' }

export function ReportsView({ data, workspace }: Props) {
  const router = useRouter()
  const pathname = usePathname()

  function setPeriod(p: string) {
    router.push(`${pathname}?period=${p}`)
  }

  const { summary, byDay, byStatus, byAgent, byInbox, period } = data

  return (
    <div className="space-y-6">
      {/* Period selector */}
      <div className="flex gap-1 rounded-lg border border-slate-200 bg-white p-1 w-fit">
        {(['7d', '30d', '90d'] as const).map((p) => (
          <button
            key={p}
            onClick={() => setPeriod(p)}
            className={[
              'rounded-md px-3 py-1.5 text-sm font-medium transition-colors',
              period === p
                ? 'bg-slate-900 text-white'
                : 'text-slate-600 hover:bg-slate-100',
            ].join(' ')}
          >
            {PERIOD_LABELS[p]}
          </button>
        ))}
      </div>

      {/* Summary cards */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="Total conversations" value={summary.total} />
        <StatCard label="Open" value={summary.open} />
        <StatCard label="Resolved" value={summary.resolved} />
        <StatCard label="New contacts" value={summary.contacts} />
        <StatCard label="Agents" value={summary.agents} />
        <StatCard label="Pending" value={summary.pending} />
        <StatCard
          label="Avg resolution time"
          value={
            summary.avgResolutionHours != null
              ? `${summary.avgResolutionHours.toFixed(1)}h`
              : '—'
          }
        />
      </div>

      {/* Conversations by day */}
      <div className="rounded-xl border border-slate-200 bg-white p-5">
        <h2 className="mb-4 text-sm font-semibold text-slate-900">Conversations over time</h2>
        <ResponsiveContainer width="100%" height={220}>
          <BarChart data={byDay} margin={{ top: 0, right: 8, left: -20, bottom: 0 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
            <XAxis
              dataKey="date"
              tick={{ fontSize: 11, fill: '#94a3b8' }}
              tickLine={false}
              axisLine={false}
              interval="preserveStartEnd"
            />
            <YAxis
              tick={{ fontSize: 11, fill: '#94a3b8' }}
              tickLine={false}
              axisLine={false}
              allowDecimals={false}
            />
            <Tooltip
              contentStyle={{
                border: '1px solid #e2e8f0',
                borderRadius: 8,
                fontSize: 12,
              }}
            />
            <Bar dataKey="conversations" fill="#6366f1" radius={[3, 3, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        {/* Status breakdown */}
        <div className="rounded-xl border border-slate-200 bg-white p-5">
          <h2 className="mb-4 text-sm font-semibold text-slate-900">By status</h2>
          {byStatus.length === 0 ? (
            <p className="text-sm text-slate-400">No data</p>
          ) : (
            <ul className="space-y-3">
              {byStatus.map((s) => (
                <li key={s.status}>
                  <div className="mb-1 flex justify-between text-xs text-slate-600">
                    <span>{s.status}</span>
                    <span>
                      {s.count} ({s.pct}%)
                    </span>
                  </div>
                  <div className="h-2 w-full rounded-full bg-slate-100">
                    <div
                      className="h-2 rounded-full bg-indigo-500"
                      style={{ width: `${s.pct}%` }}
                    />
                  </div>
                </li>
              ))}
            </ul>
          )}
        </div>

        {/* Inbox activity */}
        <div className="rounded-xl border border-slate-200 bg-white p-5">
          <h2 className="mb-4 text-sm font-semibold text-slate-900">By inbox</h2>
          {byInbox.length === 0 ? (
            <p className="text-sm text-slate-400">No data</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-slate-100 text-xs text-slate-400">
                    <th className="pb-2 text-left font-medium">Inbox</th>
                    <th className="pb-2 text-right font-medium">Total</th>
                    <th className="pb-2 text-right font-medium">Open</th>
                    <th className="pb-2 text-right font-medium">Resolved</th>
                  </tr>
                </thead>
                <tbody>
                  {byInbox.map((inbox) => (
                    <tr key={inbox.name} className="border-b border-slate-50 last:border-0">
                      <td className="py-2 text-slate-700">
                        <div>{inbox.name}</div>
                        <div className="text-xs text-slate-400">{inbox.channelType}</div>
                      </td>
                      <td className="py-2 text-right text-slate-600">{inbox.total}</td>
                      <td className="py-2 text-right text-slate-600">{inbox.open}</td>
                      <td className="py-2 text-right text-slate-600">{inbox.resolved}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>

      {/* Agent performance */}
      <div className="rounded-xl border border-slate-200 bg-white p-5">
        <h2 className="mb-4 text-sm font-semibold text-slate-900">Agent performance</h2>
        {byAgent.length === 0 ? (
          <p className="text-sm text-slate-400">No assigned conversations in this period</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-slate-100 text-xs text-slate-400">
                  <th className="pb-2 text-left font-medium">Agent</th>
                  <th className="pb-2 text-right font-medium">Total</th>
                  <th className="pb-2 text-right font-medium">Resolved</th>
                  <th className="pb-2 text-right font-medium">Resolution rate</th>
                </tr>
              </thead>
              <tbody>
                {byAgent.map((agent) => (
                  <tr key={agent.email} className="border-b border-slate-50 last:border-0">
                    <td className="py-2">
                      <div className="font-medium text-slate-800">{agent.name}</div>
                      <div className="text-xs text-slate-400">{agent.email}</div>
                    </td>
                    <td className="py-2 text-right text-slate-600">{agent.total}</td>
                    <td className="py-2 text-right text-slate-600">{agent.resolved}</td>
                    <td className="py-2 text-right">
                      <span
                        className={[
                          'rounded-full px-2 py-0.5 text-xs font-medium',
                          agent.resolutionRate >= 75
                            ? 'bg-green-50 text-green-700'
                            : agent.resolutionRate >= 50
                              ? 'bg-yellow-50 text-yellow-700'
                              : 'bg-red-50 text-red-700',
                        ].join(' ')}
                      >
                        {agent.resolutionRate}%
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  )
}

function StatCard({ label, value }: { label: string; value: number | string }) {
  return (
    <div className="rounded-xl border border-slate-200 bg-white p-4">
      <p className="text-xs text-slate-500">{label}</p>
      <p className="mt-1 text-2xl font-semibold text-slate-900">{value}</p>
    </div>
  )
}
