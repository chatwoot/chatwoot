class Captain::Copilot::Actions::SetPriority < Captain::Copilot::Actions::BaseAction
  NAME = 'set_priority'.freeze
  RESOURCE = 'conversations'.freeze
  DESCRIPTION = "Set the priority of each conversation. Arguments: priority, one of #{Conversation.priorities.keys.join(', ')}, " \
                'or null to remove it.'.freeze
  ARGUMENTS = {
    type: 'object', additionalProperties: false, required: %w[priority],
    properties: { priority: { enum: Conversation.priorities.keys + [nil] } }
  }.deep_stringify_keys.freeze

  # The same write as the dashboard's priority menu.
  def perform(conversation)
    return :skipped if conversation.priority == priority

    conversation.update!(priority: priority)
    :applied
  end

  def card(_ids)
    { summary: priority ? "SET_PRIORITY_#{priority.upcase}" : 'REMOVE_PRIORITY' }
  end

  private

  def priority
    @arguments['priority']
  end
end
