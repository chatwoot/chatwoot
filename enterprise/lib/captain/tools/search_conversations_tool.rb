class Captain::Tools::SearchConversationsTool < BaseAgentTool
  description 'Search conversations based on parameters'
  param :contact_id, type: 'number', desc: 'Filter conversations by contact ID', required: false
  param :status, type: 'string', desc: 'Filter conversations by status (open, resolved, pending, snoozed)', required: false
  param :priority, type: 'string', desc: 'Filter conversations by priority (low, medium, high, urgent)', required: false
  param :labels, type: 'string', desc: 'Filter conversations by labels (comma-separated)', required: false

  def perform(_tool_context, contact_id: nil, status: nil, priority: nil, labels: nil)
    log_tool_usage('search_conversations', { contact_id: contact_id, status: status, priority: priority, labels: labels })

    conversations = get_conversations(status, contact_id, priority, labels)

    return 'No conversations found' unless conversations.exists?

    total_count = conversations.count
    conversations = conversations.limit(100)

    <<~RESPONSE
      #{total_count > 100 ? "Found #{total_count} conversations (showing first 100)" : "Total number of conversations: #{total_count}"}
      #{conversations.map { |conversation| conversation.to_llm_text(include_contact_details: true) }.join("\n---\n")}
    RESPONSE
  end

  def active?
    user_has_permission('conversation_manage') ||
      user_has_permission('conversation_unassigned_manage') ||
      user_has_permission('conversation_participating_manage')
  end

  private

  def get_conversations(status, contact_id, priority, labels)
    conversations = permissible_conversations
    conversations = conversations.where(contact_id: contact_id) if contact_id.present?
    conversations = conversations.where(status: status) if status.present?
    conversations = conversations.where(priority: priority) if priority.present?
    if labels.present?
      label_array = labels.split(',').map(&:strip)
      conversations = conversations.tagged_with(label_array, any: true)
    end
    conversations
  end

  def permissible_conversations
    Conversations::PermissionFilterService.new(
      account_scoped(::Conversation),
      @user,
      @assistant.account
    ).perform
  end
end