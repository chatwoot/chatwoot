class Captain::Tools::Copilot::SearchConversationsService < Captain::Tools::BaseTool
  def self.name
    'search_conversation'
  end
  description 'Search conversations based on parameters'

  param :status, type: :string, desc: 'Status of the conversation'
  param :contact_id, type: :number, desc: 'Contact id'
  param :priority, type: :string, desc: 'Priority of conversation'
  param :labels, type: :string, desc: 'Labels available'

  def execute(status: nil, contact_id: nil, priority: nil, labels: nil)
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
    conversations = conversations.tagged_with(labels, any: true) if labels.present?
    conversations
  end

  def permissible_conversations
    Conversations::PermissionFilterService.new(
      @assistant.account.conversations,
      @user,
      @assistant.account
    ).perform
  end
end
