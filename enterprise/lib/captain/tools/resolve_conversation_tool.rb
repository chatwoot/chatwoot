class Captain::Tools::ResolveConversationTool < Captain::Tools::BasePublicTool
  description 'Resolve a conversation when the issue has been addressed or the conversation should be closed'
  param :reason, type: 'string', desc: 'Brief reason for resolving the conversation', required: true

  def perform(tool_context, reason:)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation
    return "Conversation ##{conversation.display_id} is already resolved" if conversation.resolved?

    log_tool_usage('resolve_conversation', { conversation_id: conversation.id, reason: reason })

    Current.captain_resolve_reason = reason
    begin
      conversation.resolved!
    ensure
      Current.captain_resolve_reason = nil
    end

    "Conversation ##{conversation.display_id} resolved#{" (Reason: #{reason})" if reason}"
  end

  private

  def permissions
    %w[conversation_manage conversation_unassigned_manage conversation_participating_manage]
  end
end
