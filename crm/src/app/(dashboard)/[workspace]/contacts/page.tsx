import Link from 'next/link'
import { notFound } from 'next/navigation'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'
import { Avatar } from '@/components/ui/avatar'
import { Button } from '@/components/ui/button'
import { UserPlus, Search } from 'lucide-react'

const PER_PAGE = 25

export default async function ContactsPage({
  params,
  searchParams,
}: {
  params: Promise<{ workspace: string }>
  searchParams: Promise<{ q?: string; page?: string }>
}) {
  const { workspace: slug } = await params
  const { q = '', page = '1' } = await searchParams

  const session = await auth()
  const account = await db.account.findUnique({
    where: { slug },
    include: { members: { where: { userId: session!.user!.id } } },
  })
  if (!account || !account.members.length) notFound()

  const pageNum = Math.max(1, parseInt(page))
  const skip = (pageNum - 1) * PER_PAGE

  const where = {
    accountId: account.id,
    ...(q && {
      OR: [
        { name: { contains: q, mode: 'insensitive' as const } },
        { email: { contains: q, mode: 'insensitive' as const } },
        { company: { contains: q, mode: 'insensitive' as const } },
      ],
    }),
  }

  const [contacts, total] = await Promise.all([
    db.contact.findMany({ where, orderBy: { name: 'asc' }, skip, take: PER_PAGE }),
    db.contact.count({ where }),
  ])

  const totalPages = Math.ceil(total / PER_PAGE)

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-slate-900">Contacts</h1>
          <p className="text-sm text-slate-500">{total} total</p>
        </div>
        <Button asChild>
          <Link href={`/${slug}/contacts/new`}>
            <UserPlus className="mr-2 h-4 w-4" />
            New contact
          </Link>
        </Button>
      </div>

      <form method="GET" className="relative max-w-sm">
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
        <input
          name="q"
          defaultValue={q}
          placeholder="Search contacts…"
          className="h-10 w-full rounded-lg border border-slate-200 bg-white pl-9 pr-3 text-sm placeholder:text-slate-400 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-900 focus-visible:ring-offset-2"
        />
      </form>

      <div className="rounded-xl border border-slate-200 bg-white overflow-hidden">
        {contacts.length === 0 ? (
          <div className="py-16 text-center text-sm text-slate-400">
            {q ? 'No contacts match your search.' : 'No contacts yet. Create your first one.'}
          </div>
        ) : (
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-slate-100 bg-slate-50 text-left text-xs font-medium text-slate-500 uppercase tracking-wide">
                <th className="px-4 py-3">Name</th>
                <th className="px-4 py-3 hidden sm:table-cell">Email</th>
                <th className="px-4 py-3 hidden md:table-cell">Phone</th>
                <th className="px-4 py-3 hidden lg:table-cell">Company</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {contacts.map((c) => (
                <tr key={c.id} className="hover:bg-slate-50 transition-colors">
                  <td className="px-4 py-3">
                    <Link
                      href={`/${slug}/contacts/${c.id}`}
                      className="flex items-center gap-3 hover:text-slate-900"
                    >
                      <Avatar name={c.name} />
                      <span className="font-medium text-slate-900">{c.name}</span>
                    </Link>
                  </td>
                  <td className="px-4 py-3 hidden sm:table-cell text-slate-500">
                    {c.email ?? '—'}
                  </td>
                  <td className="px-4 py-3 hidden md:table-cell text-slate-500">
                    {c.phone ?? '—'}
                  </td>
                  <td className="px-4 py-3 hidden lg:table-cell text-slate-500">
                    {c.company ?? '—'}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {totalPages > 1 && (
        <div className="flex items-center justify-between text-sm">
          <span className="text-slate-500">
            Page {pageNum} of {totalPages}
          </span>
          <div className="flex gap-2">
            {pageNum > 1 && (
              <Button variant="outline" size="sm" asChild>
                <Link href={`?q=${q}&page=${pageNum - 1}`}>Previous</Link>
              </Button>
            )}
            {pageNum < totalPages && (
              <Button variant="outline" size="sm" asChild>
                <Link href={`?q=${q}&page=${pageNum + 1}`}>Next</Link>
              </Button>
            )}
          </div>
        </div>
      )}
    </div>
  )
}
