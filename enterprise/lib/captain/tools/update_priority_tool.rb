class Captain::Tools::UpdatePriorityTool < Captain::Tools::BasePublicTool
  description 'Update the priority of a conversation'
  param :conversation_id, type: 'string', desc: 'The display ID of the conversation'
  param :priority, type: 'string', desc: 'The priority level: low, medium, high, urgent, or nil to remove priority'

  def perform(_tool_context, conversation_id:, priority:)
    log_tool_usage('update_priority', { conversation_id: conversation_id, priority: priority })

    error = validate_and_prepare(conversation_id, priority)
    return error if error

    execute_priority_update
  end

  private

  def validate_and_prepare(conversation_id, priority)
    return 'Missing required parameter: conversation_id' if conversation_id.blank?

    @conversation = find_conversation(conversation_id)
    return 'Conversation not found' unless @conversation

    @normalized_priority = normalize_priority(priority)
    return "Invalid priority. Valid options: #{valid_priority_options}" unless valid_priority?(@normalized_priority)

    @conversation_id = conversation_id
    nil
  end

  def execute_priority_update
    update_conversation_priority(@conversation, @normalized_priority)
    priority_text = @normalized_priority || 'none'
    "Priority updated to '#{priority_text}' for conversation #{@conversation_id}"
  end

  def find_conversation(conversation_id)
    account_scoped(::Conversation).find_by(display_id: conversation_id)
  end

  def normalize_priority(priority)
    priority == 'nil' || priority.blank? ? nil : priority
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
