class Captain::Tools::GetConversationTool < Captain::Tools::BaseAgentTool
  description 'Get details of a conversation including messages and context'
  param :conversation_id, type: 'string', desc: 'The display ID of the conversation to retrieve'

  def perform(_tool_context, conversation_id:)
    log_tool_usage('get_conversation', { conversation_id: conversation_id })

    return 'Missing required parameters' if conversation_id.blank?

    conversation = account_scoped(::Conversation).find_by(display_id: conversation_id)
    return 'Conversation not found' if conversation.nil?

    conversation.to_llm_text
  end

  def active?
    user_has_permission('conversation_manage') ||
      user_has_permission('conversation_unassigned_manage') ||
      user_has_permission('conversation_participating_manage')
  end
end