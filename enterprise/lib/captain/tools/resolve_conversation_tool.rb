class Captain::Tools::ResolveConversationTool < Captain::Tools::BasePublicTool
  description 'Resolve a conversation when the issue has been addressed or the conversation should be closed'
  param :reason, type: 'string', desc: 'Brief reason for resolving the conversation', required: true

  def perform(tool_context, reason:)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation
    return "Conversation ##{conversation.display_id} is already resolved" if conversation.resolved?

    return 'Auto-resolve is disabled for this account' if conversation.account.captain_auto_resolve_disabled?

    # Evaluate resolution guardrails to avoid premature/hallucinated resolves
    guard_result = Captain::Guards::ConversationResolutionGuard.evaluate(conversation, tool_context)

    # Log attempt (including guard decision for observability)
    log_tool_usage('resolve_conversation_attempt', {
      conversation_id: conversation.id,
      reason: reason,
      guard: {
        decision: guard_result.decision,
        score: guard_result.score,
        reasons: guard_result.reasons
      }
    })

    case guard_result.decision
    when :hard_block
      return "Cannot resolve conversation automatically (low confidence). Reasons: #{guard_result.reasons.join(', ')}"

    when :soft_block
      # Ask for explicit confirmation instead of resolving
      return "Low confidence to resolve. Ask user for confirmation before resolving. Reasons: #{guard_result.reasons.join(', ')}"

    when :allow
      log_tool_usage('resolve_conversation', {
        conversation_id: conversation.id,
        reason: reason
      })

      conversation.with_captain_activity_context(reason: reason, reason_type: :tool) do
        conversation.resolved!
      end

      "Conversation ##{conversation.display_id} resolved#{" (Reason: #{reason})" if reason}"
    end
  end

  private

  def permissions
    %w[
      conversation_manage
      conversation_unassigned_manage
      conversation_participating_manage
    ]
  end
end