class Captain::Routines::AgentTools::FindAccountResource < Captain::Routines::AgentTools::Base
  RESOURCE_OPERATIONS = {
    'agent' => 'agents.search',
    'team' => 'teams.search',
    'inbox' => 'inboxes.search',
    'label' => 'labels.search'
  }.freeze

  description 'Find an agent, team, inbox, or label in the current Chatwoot account'
  params(
    type: 'object',
    properties: {
      resource_type: { type: 'string', enum: RESOURCE_OPERATIONS.keys },
      query: { type: 'string' }
    },
    required: %w[resource_type query],
    additionalProperties: false
  )

  def name = 'find_account_resource'

  def perform(tool_context, resource_type:, query:)
    perform_operation(tool_context, RESOURCE_OPERATIONS.fetch(resource_type), query: query)
  end
end
