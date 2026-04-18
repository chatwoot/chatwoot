import { db } from '@/lib/db'

export type Period = '7d' | '30d' | '90d'

export interface ReportData {
  period: Period
  summary: {
    total: number
    open: number
    resolved: number
    pending: number
    contacts: number
    agents: number
    avgResolutionHours: number | null
  }
  byDay: { date: string; conversations: number }[]
  byStatus: { status: string; count: number; pct: number }[]
  byAgent: {
    name: string
    email: string
    total: number
    resolved: number
    resolutionRate: number
  }[]
  byInbox: {
    name: string
    channelType: string
    total: number
    open: number
    resolved: number
  }[]
}

export async function getReportData(accountId: string, period: Period): Promise<ReportData> {
  const days = period === '7d' ? 7 : period === '30d' ? 30 : 90
  const startDate = new Date(Date.now() - days * 24 * 60 * 60 * 1000)
  startDate.setHours(0, 0, 0, 0)

  const [conversations, contacts, members] = await Promise.all([
    db.conversation.findMany({
      where: { accountId, createdAt: { gte: startDate } },
      select: {
        id: true,
        status: true,
        createdAt: true,
        updatedAt: true,
        inboxId: true,
        assigneeId: true,
        inbox: { select: { name: true, channelType: true } },
        assignee: { select: { name: true, email: true } },
      },
    }),
    db.contact.count({ where: { accountId, createdAt: { gte: startDate } } }),
    db.accountMember.count({ where: { accountId } }),
  ])

  // Summary
  const open = conversations.filter((c) => c.status === 'OPEN').length
  const resolved = conversations.filter((c) => c.status === 'RESOLVED').length
  const pending = conversations.filter((c) => c.status === 'PENDING').length

  // Avg resolution time (hours) for resolved conversations
  const resolvedConvs = conversations.filter((c) => c.status === 'RESOLVED')
  const avgResolutionHours =
    resolvedConvs.length > 0
      ? resolvedConvs.reduce((sum, c) => {
          const diff = c.updatedAt.getTime() - c.createdAt.getTime()
          return sum + diff / (1000 * 60 * 60)
        }, 0) / resolvedConvs.length
      : null

  // By day — fill all days in range
  const dayMap: Record<string, number> = {}
  for (let i = days - 1; i >= 0; i--) {
    const d = new Date(Date.now() - i * 24 * 60 * 60 * 1000)
    dayMap[d.toISOString().split('T')[0]] = 0
  }
  conversations.forEach((c) => {
    const day = c.createdAt.toISOString().split('T')[0]
    if (day in dayMap) dayMap[day]++
  })
  const byDay = Object.entries(dayMap).map(([date, conversations]) => ({
    date: formatDay(date, days),
    conversations,
  }))

  // By status
  const total = conversations.length
  const statuses = [
    { status: 'Open', count: open },
    { status: 'Resolved', count: resolved },
    { status: 'Pending', count: pending },
    {
      status: 'Snoozed',
      count: conversations.filter((c) => c.status === 'SNOOZED').length,
    },
  ].filter((s) => s.count > 0)
  const byStatus = statuses.map((s) => ({
    ...s,
    pct: total > 0 ? Math.round((s.count / total) * 100) : 0,
  }))

  // By agent
  const agentMap: Record<
    string,
    { name: string; email: string; total: number; resolved: number }
  > = {}
  conversations.forEach((c) => {
    if (!c.assignee) return
    const key = c.assigneeId!
    if (!agentMap[key]) {
      agentMap[key] = {
        name: c.assignee.name ?? c.assignee.email,
        email: c.assignee.email,
        total: 0,
        resolved: 0,
      }
    }
    agentMap[key].total++
    if (c.status === 'RESOLVED') agentMap[key].resolved++
  })
  const byAgent = Object.values(agentMap)
    .sort((a, b) => b.total - a.total)
    .map((a) => ({
      ...a,
      resolutionRate:
        a.total > 0 ? Math.round((a.resolved / a.total) * 100) : 0,
    }))

  // By inbox
  const inboxMap: Record<
    string,
    { name: string; channelType: string; total: number; open: number; resolved: number }
  > = {}
  conversations.forEach((c) => {
    const key = c.inboxId
    if (!inboxMap[key]) {
      inboxMap[key] = {
        name: c.inbox.name,
        channelType: c.inbox.channelType,
        total: 0,
        open: 0,
        resolved: 0,
      }
    }
    inboxMap[key].total++
    if (c.status === 'OPEN') inboxMap[key].open++
    if (c.status === 'RESOLVED') inboxMap[key].resolved++
  })
  const byInbox = Object.values(inboxMap).sort((a, b) => b.total - a.total)

  return {
    period,
    summary: { total, open, resolved, pending, contacts, agents: members, avgResolutionHours },
    byDay,
    byStatus,
    byAgent,
    byInbox,
  }
}

function formatDay(iso: string, totalDays: number): string {
  const d = new Date(iso)
  if (totalDays <= 7) {
    return d.toLocaleDateString('en', { weekday: 'short', month: 'short', day: 'numeric' })
  }
  return d.toLocaleDateString('en', { month: 'short', day: 'numeric' })
}
