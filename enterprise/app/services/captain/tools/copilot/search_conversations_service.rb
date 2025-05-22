class Captain::Tools::Copilot::SearchConversationsService < Captain::Tools::BaseService
  def name
    'search_conversations'
  end

  def description
    'Search conversations based on parameters'
  end

  def parameters
    {
      type: 'object',
      properties: properties,
      required: []
    }
  end

  def execute(arguments)
    status = arguments['status']
    contact_id = arguments['contact_id']
    priority = arguments['priority']

    conversations = get_conversations(status, contact_id, priority)

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

  def get_conversations(status, contact_id, priority)
    conversations = permissible_conversations
    conversations = conversations.where(contact_id: contact_id) if contact_id.present?
    conversations = conversations.where(status: status) if status.present?
    conversations = conversations.where(priority: priority) if priority.present?
    conversations
  end

  def permissible_conversations
    Conversations::PermissionFilterService.new(
      @assistant.account.conversations,
      @user,
      @assistant.account
    ).perform
  end

  def properties
    {
      contact_id: {
        type: 'number',
        description: 'Filter conversations by contact ID'
      },
      status: {
        type: 'string',
        enum: %w[open resolved pending snoozed],
        description: 'Filter conversations by status'
      },
      priority: {
        type: 'string',
        enum: %w[low medium high urgent],
        description: 'Filter conversations by priority'
      }
    }
  end
end
