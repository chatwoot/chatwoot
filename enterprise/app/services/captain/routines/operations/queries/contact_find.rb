class Captain::Routines::Operations::Queries::ContactFind < Captain::Routines::Operations::Query
  returns :one, of: :contact

  configure(
    name: 'contacts.find', effect: 'read',
    description: 'Load one contact with identity, labels, notes, and custom attributes.',
    arguments: { contact_id: 'contact ID or reference' }, required: %w[contact_id]
  )

  def execute(contact_id:)
    contact = contact!(contact_id)
    contact_data(contact).merge(
      'notes' => contact.notes.reorder(created_at: :desc).limit(20).map do |note|
        { 'id' => note.id, 'content' => note.content, 'created_at' => note.created_at.iso8601 }
      end
    )
  end
end
