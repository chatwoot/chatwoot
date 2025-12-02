class Captain::Tools::UpdatePriorityTool < Captain::Tools::BasePublicTool
  description 'Modify the priority level of the active conversation'
  param :priority, type: 'string', desc: 'New priority: low, medium, high, urgent, or nil to clear'

  def perform(context, priority:)
    conversation = find_conversation(context.state)
    return 'Error: Conversation context missing' unless conversation

    normalized = normalize_priority(priority)

    return "Error: Invalid priority '#{priority}'. Allowed: #{allowed_priorities_list}" unless valid_priority?(normalized)

    log_tool_usage('priority_update', {
                     conversation_id: conversation.id,
                     new_priority: normalized
                   })

    update_priority(conversation, normalized)

    "Priority successfully changed to '#{normalized || 'none'}' for conversation ##{conversation.display_id}"
  end

  def permissions
    %w[conversation_manage conversation_unassigned_manage conversation_participating_manage]
  end

  private

  def normalize_priority(value)
    return nil if value.blank? || value == 'nil'

    value.downcase
  end

  def valid_priority?(value)
    allowed_priorities.include?(value)
  end

  def allowed_priorities
    [nil] + ::Conversation.priorities.keys
  end

  def allowed_priorities_list
    (allowed_priorities.compact + ['nil']).join(', ')
  end

  def update_priority(conversation, value)
    conversation.update!(priority: value)
  end
end
