class Captain::Copilot::Actions::SetPriority < Captain::Copilot::Actions::BaseAction
  NAME = 'set_priority'.freeze
  RESOURCE = 'conversations'.freeze
  DESCRIPTION = "Set the priority of each conversation. Arguments: priority, one of #{Conversation.priorities.keys.join(', ')}.".freeze
  ARGUMENTS = {
    type: 'object', additionalProperties: false, required: %w[priority],
    properties: { priority: { type: 'string', enum: Conversation.priorities.keys } }
  }.deep_stringify_keys.freeze

  def perform(conversation)
    return 'skipped' if conversation.priority == @arguments['priority']

    conversation.update!(priority: @arguments['priority'])
    'applied'
  end
end
