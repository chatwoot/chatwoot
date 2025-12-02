class Captain::Tools::AddLabelToConversationTool < Captain::Tools::BasePublicTool
  description 'Attach a label to the current conversation'
  param :label_name, type: 'string', desc: 'Name of the label to apply'

  def perform(context, label_name:)
    conversation = find_conversation(context.state)
    return 'Error: Conversation context missing' unless conversation

    normalized_name = normalize_label(label_name)
    return 'Error: Label name required' if normalized_name.blank?

    return "Error: Label '#{normalized_name}' does not exist" unless label_exists?(normalized_name)

    apply_label(conversation, normalized_name)

    log_tool_usage('label_applied', {
                     conversation_id: conversation.id,
                     label: normalized_name
                   })

    "Label '#{normalized_name}' successfully applied to conversation"
  end

  private

  def normalize_label(name)
    name&.strip&.downcase
  end

  def label_exists?(name)
    account_scoped(Label).exists?(title: name)
  end

  def apply_label(conversation, name)
    conversation.add_labels(name)
  rescue StandardError => e
    Rails.logger.error("Label application failed: #{e.message}")
    raise
  end
end
