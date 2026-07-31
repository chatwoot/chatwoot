class Captain::Tools::ResolveConversationTool < Captain::Tools::BasePublicTool
  description 'Resolve a conversation when the issue has been addressed or the conversation should be closed'
  param :reason, type: 'string', desc: 'Brief reason for resolving the conversation', required: true

  def perform(tool_context, reason:)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation
    return "Conversation ##{conversation.display_id} is already resolved" if conversation.resolved?
    return 'Auto-resolve is disabled for this account' if conversation.account.captain_auto_resolve_disabled?

    result = resolve_conversation(conversation, reason)

    return "Conversation ##{conversation.display_id} is already resolved" if result == :resolved
    return 'Resolve skipped because the conversation changed' unless result == :completed

    "Conversation ##{conversation.display_id} resolved#{" (Reason: #{reason})" if reason}"
  end

  private

  def resolve_conversation(conversation, reason)
    conversation.reload
    conversation.with_captain_activity_context(reason: reason, reason_type: :tool) do
      conversation.with_lock do
        next :resolved if conversation.resolved?
        next :changed if conversation.assignee_agent_bot_id.present?

        log_tool_usage('resolve_conversation', { conversation_id: conversation.id, reason: reason })
        conversation.resolved!
        :completed
      end
    end
  end

  def permissions
    %w[conversation_manage conversation_unassigned_manage conversation_participating_manage]
  end
end
