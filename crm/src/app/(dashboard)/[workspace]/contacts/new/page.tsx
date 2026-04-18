import { createContact } from '@/app/actions/contacts'
import { ContactForm } from '@/components/contacts/contact-form'

export default async function NewContactPage({
  params,
}: {
  params: Promise<{ workspace: string }>
}) {
  const { workspace } = await params

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-2xl font-semibold text-slate-900">New contact</h1>
        <p className="text-sm text-slate-500">Add a new contact to your workspace</p>
      </div>
      <ContactForm action={createContact} workspace={workspace} />
    </div>
  )
}
