class Captain::Routines::Operations::Queries::InboxGetAvailability < Captain::Routines::Operations::Query
  returns :one

  configure(
    name: 'inboxes.get_availability', effect: 'read',
    description: 'Evaluate an inbox business-hours status at the immutable Routine execution start time.',
    arguments: { inbox_id: 'inbox ID or reference' }, required: %w[inbox_id]
  )
end
