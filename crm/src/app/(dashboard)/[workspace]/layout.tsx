import { notFound, redirect } from 'next/navigation'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'
import { Sidebar } from '@/components/dashboard/sidebar'
import { Header } from '@/components/dashboard/header'

export default async function WorkspaceLayout({
  children,
  params,
}: {
  children: React.ReactNode
  params: Promise<{ workspace: string }>
}) {
  const { workspace: slug } = await params
  const session = await auth()

  if (!session?.user) redirect('/login')

  const account = await db.account.findUnique({
    where: { slug },
    include: {
      members: { where: { userId: session.user.id } },
    },
  })

  if (!account || account.members.length === 0) notFound()

  return (
    <div className="flex h-screen overflow-hidden bg-slate-50">
      <Sidebar workspace={account.name} />
      <div className="flex flex-1 flex-col overflow-hidden">
        <Header userName={session.user.name ?? session.user.email ?? ''} />
        <main className="flex-1 overflow-auto p-6">{children}</main>
      </div>
    </div>
  )
}
