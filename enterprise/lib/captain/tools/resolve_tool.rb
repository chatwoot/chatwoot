class Captain::Tools::ResolveTool < Captain::Tools::BasePublicTool
  description 'Mark the conversation as resolved when the issue has been addressed'
  param :reason, type: 'string', desc: 'The reason why the conversation is being resolved (optional)', required: false

  def perform(tool_context, reason: nil)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    return 'Conversation is already resolved' if conversation.resolved?

    log_tool_usage('tool_resolve', {
                     conversation_id: conversation.id,
                     reason: reason || 'Agent resolved conversation'
                   })

    resolve_conversation(conversation, reason)

    "Conversation marked as resolved#{" (Reason: #{reason})" if reason.present?}"
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    'Failed to resolve conversation'
  end

  private

  def resolve_conversation(conversation, reason)
    # Add a private note with the reason if provided
    if reason.present?
      conversation.messages.create!(
        message_type: :outgoing,
        private: true,
        sender: @assistant,
        account: conversation.account,
        inbox: conversation.inbox,
        content: "Resolved: #{reason}"
      )
    end

    # Mark conversation as resolved
    Current.tool_name = 'resolve'
    conversation.resolved!
  ensure
    Current.tool_name = nil
  end

  def permissions
    %w[conversation_manage conversation_unassigned_manage conversation_participating_manage]
  end
end
