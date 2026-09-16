class Captain::Tools::AddLabelToConversationTool < Captain::Tools::BasePublicTool
  description 'Add a label to a conversation'
  param :label_name, type: 'string', desc: 'The name of the label to add'

  def perform(tool_context, label_name:)
    conversation = find_conversation(tool_context.state)
    return failure_result('Conversation not found', tool_context.state) unless conversation

    label_name = label_name&.strip&.downcase
    return failure_result('Label name is required', tool_context.state) if label_name.blank?

    label = find_label(label_name)
    return failure_result('Label not found', tool_context.state) unless label

    add_label_to_conversation(conversation, label_name)

    log_tool_usage('added_label', conversation_id: conversation.id, label: label_name)

    "Label '#{label_name}' added to conversation ##{conversation.display_id}"
  end

  private

  def find_label(label_name)
    account_scoped(Label).find_by(title: label_name)
  end

  def add_label_to_conversation(conversation, label_name)
    conversation.add_labels(label_name)
  rescue StandardError => e
    Rails.logger.error "Failed to add label to conversation: #{e.message}"
    raise
  end
end
