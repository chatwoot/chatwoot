class Captain::Routines::Operations::Queries::InboxSearch < Captain::Routines::Operations::Query
  returns :one

  configure(
    name: 'inboxes.search', effect: 'read',
    description: 'Resolve an account inbox by name or ID.',
    arguments: { query: 'inbox name or ID', channel_type: 'optional Chatwoot channel type' }, required: %w[query]
  )

  def execute(query:, channel_type: nil)
    inbox = inbox!(query)
    raise ActiveRecord::RecordNotFound, "Inbox '#{query}' does not use #{channel_type}" if channel_type.present? && inbox.channel_type != channel_type

    inbox_data(inbox)
  end
end
