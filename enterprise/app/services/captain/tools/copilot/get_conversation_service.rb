class Captain::Tools::Copilot::GetConversationService < Captain::Tools::BaseService
  def name
    'get_conversation'
  end

  def description
    'Get details of a conversation including messages and contact information'
  end

  def parameters
    {
      type: 'object',
      properties: {
        conversation_id: {
          type: 'number',
          description: 'The ID of the conversation to retrieve'
        },
        account_id: {
          type: 'number',
          description: 'The ID of the account the conversation belongs to'
        }
      },
      required: %w[conversation_id account_id]
    }
  end

  def execute(arguments)
    conversation_id = arguments['conversation_id']
    account_id = arguments['account_id']

    Rails.logger.info { "[CAPTAIN][GetConversation] #{conversation_id}, #{account_id}" }

    return 'Missing required parameters' if conversation_id.blank? || account_id.blank?

    conversation = Conversation.find_by(display_id: conversation_id, account_id: account_id)
    return 'Conversation not found' unless conversation

    conversation.to_llm_text
  end
end
