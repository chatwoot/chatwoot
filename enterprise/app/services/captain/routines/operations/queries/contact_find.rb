class Captain::Routines::Operations::Queries::ContactFind < Captain::Routines::Operations::Query
  returns :one

  configure(
    name: 'contacts.find', effect: 'read',
    description: 'Load one contact with identity, labels, notes, and custom attributes.',
    arguments: { contact_id: 'contact ID or reference' }, required: %w[contact_id]
  )
end
