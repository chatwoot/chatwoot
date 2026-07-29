class Captain::Tools::Copilot::GetConversationService < Captain::Tools::BaseTool
  def self.name
    'get_conversation'
  end
  description 'Get details of a conversation including messages and contact information'

  param :conversation_id, type: :integer, desc: 'ID of the conversation to retrieve', required: true

  def execute(conversation_id:)
    conversation = permissible_conversations.find_by(display_id: conversation_id)
    return 'Conversation not found' if conversation.blank?

    conversation.to_llm_text(include_private_messages: true)
  end

  def active?
    user_has_permission('conversation_manage') ||
      user_has_permission('conversation_unassigned_manage') ||
      user_has_permission('conversation_participating_manage')
  end

  private

  def permissible_conversations
    Conversations::PermissionFilterService.new(
      @assistant.account.conversations,
      @user,
      @assistant.account
    ).perform
  end
end
