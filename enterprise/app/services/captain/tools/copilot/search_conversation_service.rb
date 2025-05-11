class Captain::Tools::Copilot::SearchConversationService < Captain::Tools::BaseService
  def name
    'search_conversation'
  end

  def description
    'Search for conversations based on query parameters'
  end

  def parameters
    {
      type: 'object',
      properties: {
        account_id: {
          type: 'number',
          description: 'The ID of the account to search conversations in'
        },
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
      },
      required: %w[account_id]
    }
  end

  def execute(arguments)
    account_id = arguments['account_id']
    status = arguments['status']
    contact_id = arguments['contact_id']
    priority = arguments['priority']

    Rails.logger.info do
      "[CAPTAIN][SearchConversation] account_id: #{account_id}, status: #{status}, contact_id: #{contact_id}, priority: #{priority}"
    end

    return 'Missing required parameters' if account_id.blank?

    conversations = Conversation.where(account_id: account_id)
    conversations = conversations.where(contact_id: contact_id) if contact_id.present?
    conversations = conversations.where(status: status) if status.present?
    conversations = conversations.where(priority: priority) if priority.present?

    return 'No conversations found' unless conversations.exists?

    <<~RESPONSE
      Total number of conversations: #{conversations.count}
      #{
        conversations.map do |conversation|
          conversation.to_llm_text(include_contact_details: true)
        end.join("\n---\n")
      }
    RESPONSE
  end
end
