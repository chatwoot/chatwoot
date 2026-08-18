class Captain::Routines::AgentTools::GetCurrentMessages < Captain::Routines::AgentTools::Base
  description 'Get recent messages from the current conversation'
  param :limit, type: 'integer', desc: 'Maximum number of messages from 1 to 100', required: false
  param :include_private, type: 'boolean', desc: 'Whether to include internal private notes', required: false

  def name = 'get_current_messages'

  def perform(tool_context, limit: 20, include_private: false)
    perform_operation(
      tool_context,
      'conversations.get_messages',
      conversation_id: current_conversation_id(tool_context),
      limit: limit,
      include_private: include_private
    )
  end
end
