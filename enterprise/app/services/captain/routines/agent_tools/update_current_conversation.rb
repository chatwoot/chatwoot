class Captain::Routines::AgentTools::UpdateCurrentConversation < Captain::Routines::AgentTools::Base
  ACTIONS = {
    'set_priority' => ['conversations.set_priority', :priority],
    'add_label' => ['conversations.add_label', :label],
    'remove_label' => ['conversations.remove_label', :label],
    'assign_agent' => ['conversations.assign_agent', :agent],
    'assign_team' => ['conversations.assign_team', :team],
    'set_status' => ['conversations.set_status', :status],
    'snooze' => ['conversations.snooze', :until]
  }.freeze

  description 'Update the current conversation priority, labels, assignment, status, or snooze time'
  params(
    type: 'object',
    properties: {
      action: { type: 'string', enum: ACTIONS.keys },
      value: { type: 'string', description: 'The priority, label, agent, team, status, or snooze time required by the action' }
    },
    required: %w[action value],
    additionalProperties: false
  )

  def name = 'update_current_conversation'

  def perform(tool_context, action:, value:)
    operation, argument = ACTIONS.fetch(action)
    arguments = { conversation_id: current_conversation_id(tool_context) }
    arguments[argument] = value
    perform_operation(tool_context, operation, arguments)
  end
end
