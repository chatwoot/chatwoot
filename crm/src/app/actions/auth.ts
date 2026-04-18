'use server'

import { signIn, signOut } from '@/lib/auth'
import { db } from '@/lib/db'
import { slugify } from '@/lib/utils'
import bcrypt from 'bcryptjs'

type AuthState = { error: string } | undefined

export async function login(_prev: AuthState, formData: FormData): Promise<AuthState> {
  const email = formData.get('email') as string
  const password = formData.get('password') as string

  try {
    const member = await db.accountMember.findFirst({
      where: { user: { email } },
      include: { account: true },
    })

    const slug = member?.account.slug ?? ''

    await signIn('credentials', {
      email,
      password,
      redirectTo: slug ? `/${slug}` : '/onboarding',
    })
  } catch {
    return { error: 'Invalid email or password' }
  }
}

export async function register(_prev: AuthState, formData: FormData): Promise<AuthState> {
  const name = formData.get('name') as string
  const email = formData.get('email') as string
  const password = formData.get('password') as string
  const workspaceName = formData.get('workspaceName') as string

  if (!name || !email || !password || !workspaceName) {
    return { error: 'All fields are required' }
  }

  const existing = await db.user.findUnique({ where: { email } })
  if (existing) return { error: 'Email already in use' }

  const hashed = await bcrypt.hash(password, 12)

  const slug = slugify(workspaceName)
  const existingSlug = await db.account.findUnique({ where: { slug } })
  const finalSlug = existingSlug ? `${slug}-${Date.now()}` : slug

  await db.user.create({
    data: {
      name,
      email,
      password: hashed,
      accounts: {
        create: {
          role: 'OWNER',
          account: {
            create: { name: workspaceName, slug: finalSlug },
          },
        },
      },
    },
  })

  await signIn('credentials', {
    email,
    password,
    redirectTo: `/${finalSlug}`,
  })
}

export async function logout() {
  await signOut({ redirectTo: '/login' })
}
