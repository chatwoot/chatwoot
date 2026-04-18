import { redirect } from 'next/navigation'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'

export default async function RootPage() {
  const session = await auth()

  if (!session?.user) redirect('/login')

  const member = await db.accountMember.findFirst({
    where: { userId: session.user.id },
    include: { account: true },
  })

  if (member) redirect(`/${member.account.slug}`)

  redirect('/onboarding')
}
