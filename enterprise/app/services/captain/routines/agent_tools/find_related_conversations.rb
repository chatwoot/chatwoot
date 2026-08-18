class Captain::Routines::AgentTools::FindRelatedConversations < Captain::Routines::AgentTools::Base
  description 'Find other conversations belonging to the current contact using optional status, label, and time filters'
  params(
    type: 'object',
    properties: {
      status: { type: 'string', enum: %w[open resolved pending snoozed] },
      labels: { type: 'array', items: { type: 'string' } },
      created: { type: 'string', description: 'Relative date or range such as previous 90 days' },
      last_activity: { type: 'string', description: 'Relative date or range' },
      limit: { type: 'integer', minimum: 1, maximum: 100 }
    },
    additionalProperties: false
  )

  def name = 'find_related_conversations'

  def perform(tool_context, limit: 20, **filters)
    contact = current_conversation(tool_context).contact
    return { status: 'not_found', reason: 'The current conversation has no contact' }.to_json unless contact

    arguments = filters.slice(:status, :labels, :created, :last_activity).merge(contact: contact.id).compact
    response = JSON.parse(perform_operation(tool_context, 'conversations.search', arguments))
    if response['status'] == 'completed'
      response['result'] = Array(response['result']).reject { |item| item['id'] == current_conversation_id(tool_context) }.first(limit)
    end
    response.to_json
  end
end
