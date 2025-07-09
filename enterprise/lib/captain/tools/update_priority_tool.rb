class Captain::Tools::UpdatePriorityTool < Captain::Tools::BaseAgentTool
  description 'Update the priority of a conversation'
  param :conversation_id, type: 'string', desc: 'The display ID of the conversation'
  param :priority, type: 'string', desc: 'The priority level: nil, low, medium, high, urgent'

  def perform(_tool_context, conversation_id:, priority:)
    log_tool_usage('update_priority', { conversation_id: conversation_id, priority: priority })

    return 'Missing required parameters' if conversation_id.blank?

    conversation = account_scoped(::Conversation).find_by(display_id: conversation_id)
    return 'Conversation not found' if conversation.nil?

    # Validate priority value
    valid_priorities = [nil, 'low', 'medium', 'high', 'urgent']
    priority = nil if priority == 'nil' || priority.blank?

    return "Invalid priority. Valid options: #{valid_priorities.join(', ')}" unless valid_priorities.include?(priority)

    # Update the priority
    conversation.update!(priority: priority)

    priority_text = priority || 'none'
    "Priority updated to '#{priority_text}' for conversation #{conversation_id}"
  end

  def active?
    user_has_permission('conversation_manage') ||
      user_has_permission('conversation_unassigned_manage') ||
      user_has_permission('conversation_participating_manage')
  end
end