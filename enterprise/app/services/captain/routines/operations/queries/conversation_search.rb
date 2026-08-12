class Captain::Routines::Operations::Queries::ConversationSearch < Captain::Routines::Operations::Query
  returns :collection

  configure(
    name: 'conversations.search', effect: 'read', approval: 'never',
    description: 'Find conversations using deterministic filters.',
    arguments: {
      status: 'open, resolved, pending, or snoozed', inbox: 'inbox name or ID',
      contact: 'contact name, email, phone number, ID, or reference',
      assignee: 'agent name, email, ID, or unassigned', team: 'team name, ID, or unassigned',
      waiting_for: 'agent_reply or customer_reply', waiting_longer_than: 'duration such as 12h',
      snooze_due: 'relative date such as today, evaluated against snoozed_until in the account timezone',
      priority: 'low, medium, high, or urgent', labels: 'array of label names',
      created: 'relative date or range', last_activity: 'relative date or range'
    }
  )
end
