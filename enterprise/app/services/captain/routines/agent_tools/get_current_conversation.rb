class Captain::Routines::AgentTools::GetCurrentConversation < Captain::Routines::AgentTools::Base
  description 'Get the current conversation, including its contact, inbox, assignments, labels, and attributes'

  def name = 'get_current_conversation'

  def perform(tool_context)
    perform_operation(
      tool_context,
      'conversations.find',
      conversation_id: current_conversation_id(tool_context)
    )
  end
end
