class Captain::Tools::UpdatePriorityTool < Captain::Tools::BasePublicTool
  description 'Update the priority of a conversation'
  param :priority, type: 'string', desc: 'The priority level: low, medium, high, urgent, or nil to remove priority'

  def perform(tool_context, priority:)
    @conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless @conversation

    @normalized_priority = normalize_priority(priority)
    return "Invalid priority. Valid options: #{valid_priority_options}" unless valid_priority?(@normalized_priority)

    log_tool_usage('update_priority', { conversation_id: @conversation.id, priority: priority })

    execute_priority_update
  end

  private

  def execute_priority_update
    update_conversation_priority(@conversation, @normalized_priority)
    priority_text = @normalized_priority || 'none'
    "Priority updated to '#{priority_text}' for conversation ##{@conversation.display_id}"
  end

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

  def update_conversation_priority(conversation, priority)
    conversation.update!(priority: priority)
  end

  def permissions
    %w[conversation_manage conversation_unassigned_manage conversation_participating_manage]
  end
end
