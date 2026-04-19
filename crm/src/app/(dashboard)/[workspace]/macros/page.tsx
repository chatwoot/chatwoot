import { notFound } from 'next/navigation'
import Link from 'next/link'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'
import { deleteMacro } from '@/app/actions/macros'
import { Button } from '@/components/ui/button'
import { Plus, Pencil, Trash2 } from 'lucide-react'

export default async function MacrosPage({
  params,
}: {
  params: Promise<{ workspace: string }>
}) {
  const { workspace: slug } = await params
  const session = await auth()

  const account = await db.account.findUnique({
    where: { slug },
    include: { members: { where: { userId: session!.user!.id } } },
  })
  if (!account || !account.members.length) notFound()

  const macros = await db.macro.findMany({
    where: { accountId: account.id },
    orderBy: { createdAt: 'desc' },
  })

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-slate-900">Macros</h1>
          <p className="text-sm text-slate-500">One-click action sequences run from conversations</p>
        </div>
        <Button asChild>
          <Link href={`/${slug}/macros/new`}>
            <Plus className="mr-1.5 h-4 w-4" />
            New macro
          </Link>
        </Button>
      </div>

      {macros.length === 0 ? (
        <div className="rounded-xl border border-dashed border-slate-200 bg-white p-10 text-center">
          <p className="text-sm text-slate-500">No macros yet.</p>
          <Button asChild className="mt-4" variant="outline">
            <Link href={`/${slug}/macros/new`}>Create your first macro</Link>
          </Button>
        </div>
      ) : (
        <ul className="space-y-2">
          {macros.map((m) => (
            <li
              key={m.id}
              className="flex items-center justify-between gap-4 rounded-xl border border-slate-200 bg-white px-4 py-3"
            >
              <div className="min-w-0">
                <p className="truncate text-sm font-medium text-slate-900">{m.name}</p>
                <p className="text-xs text-slate-400">
                  {(m.actions as unknown[]).length} action
                  {(m.actions as unknown[]).length !== 1 ? 's' : ''}
                </p>
              </div>
              <div className="flex shrink-0 items-center gap-2">
                <Button variant="ghost" size="icon" asChild>
                  <Link href={`/${slug}/macros/${m.id}`}>
                    <Pencil className="h-3.5 w-3.5" />
                  </Link>
                </Button>
                <form
                  action={async () => {
                    'use server'
                    await deleteMacro(slug, m.id)
                  }}
                >
                  <Button variant="ghost" size="icon" type="submit">
                    <Trash2 className="h-3.5 w-3.5 text-red-400" />
                  </Button>
                </form>
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}
