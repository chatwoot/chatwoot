class Captain::Tools::Copilot::GetConversationService < Captain::Tools::BaseTool
  include Captain::Copilot::ConversationAccess

  def self.name
    'get_conversation'
  end
  description 'Get details of a conversation including messages and contact information'

  parameter :conversation_id, type: :integer, description: 'ID of the conversation to retrieve', required: true

  def execute(conversation_id:)
    conversation = accessible_conversation(account: @assistant.account, user: @user, display_id: conversation_id)
    return 'Conversation not found' if conversation.blank?

    # Only the ID: contact details stay behind get_contact and its contact_manage permission.
    "#{conversation.to_llm_text(include_private_messages: true)}\nContact ID: ##{conversation.contact_id}"
  end

  def active?
    user_has_permission('conversation_manage') ||
      user_has_permission('conversation_unassigned_manage') ||
      user_has_permission('conversation_participating_manage')
  end
end
