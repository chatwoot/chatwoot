class Captain::Tools::UpdatePriorityTool < Captain::Tools::BasePublicTool
  description 'Update the priority of a conversation'
  parameter :priority, type: 'string', description: 'The priority level: low, medium, high, urgent, or nil to remove priority'

  def perform(tool_context, priority:)
    conversation = find_conversation(tool_context.state)
    return failure_result('Conversation not found', tool_context.state) unless conversation

    normalized_priority = normalize_priority(priority)
    unless valid_priority?(normalized_priority)
      return failure_result("Invalid priority. Valid options: #{valid_priority_options}", tool_context.state)
    end

    log_tool_usage('update_priority', { conversation_id: conversation.id, priority: priority })

    conversation.update!(priority: normalized_priority)
    "Priority updated to '#{normalized_priority || 'none'}' for conversation ##{conversation.display_id}"
  end

  private

  def normalize_priority(priority)
    return nil if priority == 'nil' || priority.blank?

    priority.downcase
  end

  def valid_priority?(priority)
    valid_priorities.include?(priority)
  end

  def valid_priorities
    @valid_priorities ||= [nil] + Conversation.priorities.keys
  end

  def valid_priority_options
    (valid_priorities.compact + ['nil']).join(', ')
  end
end
