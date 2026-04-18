'use server'

import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'

async function resolveAccountId(slug: string, userId: string) {
  const member = await db.accountMember.findFirst({
    where: { account: { slug }, userId },
    include: { account: true },
  })
  if (!member) throw new Error('Unauthorized')
  return member.account.id
}

type ContactState = { error: string } | undefined

export async function createContact(
  _prev: ContactState,
  formData: FormData,
): Promise<ContactState> {
  const session = await auth()
  if (!session?.user?.id) return { error: 'Unauthorized' }

  const slug = formData.get('workspace') as string
  const name = formData.get('name') as string
  const email = (formData.get('email') as string) || undefined
  const phone = (formData.get('phone') as string) || undefined
  const company = (formData.get('company') as string) || undefined

  if (!name) return { error: 'Name is required' }

  const accountId = await resolveAccountId(slug, session.user.id)

  if (email) {
    const exists = await db.contact.findUnique({ where: { accountId_email: { accountId, email } } })
    if (exists) return { error: 'A contact with this email already exists' }
  }

  await db.contact.create({ data: { accountId, name, email, phone, company } })

  revalidatePath(`/${slug}/contacts`)
  redirect(`/${slug}/contacts`)
}

export async function updateContact(
  _prev: ContactState,
  formData: FormData,
): Promise<ContactState> {
  const session = await auth()
  if (!session?.user?.id) return { error: 'Unauthorized' }

  const slug = formData.get('workspace') as string
  const id = formData.get('id') as string
  const name = formData.get('name') as string
  const email = (formData.get('email') as string) || undefined
  const phone = (formData.get('phone') as string) || undefined
  const company = (formData.get('company') as string) || undefined

  if (!name) return { error: 'Name is required' }

  const accountId = await resolveAccountId(slug, session.user.id)

  const contact = await db.contact.findFirst({ where: { id, accountId } })
  if (!contact) return { error: 'Contact not found' }

  await db.contact.update({ where: { id }, data: { name, email, phone, company } })

  revalidatePath(`/${slug}/contacts`)
  revalidatePath(`/${slug}/contacts/${id}`)
  redirect(`/${slug}/contacts/${id}`)
}

export async function deleteContact(slug: string, id: string) {
  const session = await auth()
  if (!session?.user?.id) throw new Error('Unauthorized')

  const accountId = await resolveAccountId(slug, session.user.id)
  const contact = await db.contact.findFirst({ where: { id, accountId } })
  if (!contact) throw new Error('Contact not found')

  await db.contact.delete({ where: { id } })

  revalidatePath(`/${slug}/contacts`)
  redirect(`/${slug}/contacts`)
}
