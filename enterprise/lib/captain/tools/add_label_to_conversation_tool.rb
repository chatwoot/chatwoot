class Captain::Tools::AddLabelToConversationTool < Captain::Tools::BaseAgentTool
  description 'Add a label to a conversation'
  param :conversation_id, type: 'integer', desc: 'The ID of the conversation'
  param :label_name, type: 'string', desc: 'The name of the label to add'

  def perform(_tool_context, conversation_id:, label_name:)
    label_name = label_name&.strip&.downcase

    return error_response('Conversation ID is required') if conversation_id.blank?
    return error_response('Label name is required') if label_name.blank?

    conversation = find_conversation(conversation_id)
    return error_response('Conversation not found') unless conversation

    label = find_or_create_label(label_name)
    return error_response('Failed to find or create label') unless label

    add_label_to_conversation(conversation, label_name)

    log_tool_usage('added_label', conversation_id: conversation_id, label: label_name)

    success_response(conversation, label_name)
  end

  private

  def find_conversation(conversation_id)
    account_scoped(Conversation).find_by(id: conversation_id)
  end

  def find_or_create_label(label_name)
    account_scoped(Label).find_or_create_by(title: label_name)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to create label: #{e.message}"
    nil
  end

  def add_label_to_conversation(conversation, label_name)
    conversation.add_labels(label_name)
  rescue StandardError => e
    Rails.logger.error "Failed to add label to conversation: #{e.message}"
    raise
  end

  def success_response(conversation, label_name)
    {
      success: true,
      message: "Label '#{label_name}' added to conversation ##{conversation.display_id}",
      conversation_id: conversation.id,
      display_id: conversation.display_id,
      label: label_name,
      all_labels: conversation.label_list
    }
  end

  def error_response(message)
    {
      success: false,
      error: message
    }
  end
end