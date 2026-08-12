class Captain::Routines::Operations::Queries::InboxSearch < Captain::Routines::Operations::Query
  returns :one

  configure(
    name: 'inboxes.search', effect: 'read',
    description: 'Resolve an account inbox by name or ID.',
    arguments: { query: 'inbox name or ID', channel_type: 'optional Chatwoot channel type' }, required: %w[query]
  )
end
