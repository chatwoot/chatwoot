class Captain::Tools::ResolveConversationTool < Captain::Tools::BasePublicTool
  description 'Resolve a conversation when the issue has been addressed or the conversation should be closed'
  parameter :reason, type: 'string', description: 'Brief reason for resolving the conversation', required: true

  def perform(tool_context, reason:)
    state = tool_context.state
    conversation = find_conversation(state)
    return failure_result('Conversation not found', state) unless conversation
    return failure_result("Conversation ##{conversation.display_id} is already resolved", state) if conversation.resolved?
    return failure_result('Auto-resolve is disabled for this assistant', state) if @assistant.inactive_conversation_resolution_disabled?
    unless conversation.captain_assigned?(@assistant) && !conversation.snoozed?
      return failure_result('Conversation is not available to this assistant', state)
    end

    log_tool_usage('resolve_conversation', { conversation_id: conversation.id, reason: reason })

    conversation.with_captain_activity_context(reason: reason, reason_type: :tool) do
      Conversation.transaction do
        Captain::Conversation::ResolutionMessageService.new(conversation: conversation, assistant: @assistant).perform
        conversation.resolved!
      end
    end
    Captain::ConversationEvents.resolved(conversation: conversation, assistant: @assistant,
                                         source: Captain::ConversationEvents::Sources::TOOL, at: Time.current)

    "Conversation ##{conversation.display_id} resolved#{" (Reason: #{reason})" if reason}"
  end

  private

  def permissions
    %w[conversation_manage conversation_unassigned_manage conversation_participating_manage]
  end
end
