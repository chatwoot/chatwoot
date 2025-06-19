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
        }
      },
      required: %w[conversation_id]
    }
  end

  def execute(arguments)
    conversation_id = arguments['conversation_id']

    Rails.logger.info "#{self.class.name}: Conversation ID: #{conversation_id}"

    return 'Missing required parameters' if conversation_id.blank?

    conversation = Conversation.find_by(display_id: conversation_id, account_id: @assistant.account_id)
    return 'Conversation not found' if conversation.blank?

    conversation.to_llm_text
  end

  def active?
    user_has_permission('conversation_manage') ||
      user_has_permission('conversation_unassigned_manage') ||
      user_has_permission('conversation_participating_manage')
  end
end
