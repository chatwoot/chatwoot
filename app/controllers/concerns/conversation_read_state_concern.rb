module ConversationReadStateConcern
  extend ActiveSupport::Concern

  def update_last_seen
    # High-traffic accounts generate excessive DB writes when agents frequently switch between conversations.
    # Throttle last_seen updates to once per hour when there are no unread messages to reduce DB load.
    # Always update immediately if there are unread messages to maintain accurate read/unread state.
    # Visiting a conversation should clear any unread inbox notifications for this conversation.
    Notification::MarkConversationReadService.new(user: Current.user, account: Current.account, conversation: @conversation).perform
    return @conversation.read_state_for(Current.user).mark_read if individual_conversation_reads?

    unread_messages = assignee? ? @conversation.assignee_unread_messages : @conversation.unread_messages
    update_last_seen_on_conversation(DateTime.now.utc, assignee?) if unread_messages.any? || should_update_last_seen?
  end

  def unread
    return @conversation.read_state_for(Current.user).mark_unread if individual_conversation_reads?

    last_incoming_message = @conversation.messages.incoming.last
    last_seen_at = last_incoming_message.created_at - 1.second if last_incoming_message.present?
    update_last_seen_on_conversation(last_seen_at, true)
  end

  private

  def individual_conversation_reads?
    ::Conversations::ReadStateService.enabled?(Current.account, Current.user)
  end

  def update_last_seen_on_conversation(last_seen_at, update_assignee)
    updates = { agent_last_seen_at: last_seen_at }
    updates[:assignee_last_seen_at] = last_seen_at if update_assignee.present?

    # rubocop:disable Rails/SkipsModelValidations
    @conversation.update_columns(updates)
    # rubocop:enable Rails/SkipsModelValidations

    ::Conversations::UnreadCounts::Notifier.new(@conversation).perform
    ::Conversations::UnreadCounts::FilteredCountInvalidator.new(Current.account).conversation_changed!
  end

  def should_update_last_seen?
    # Update if at least one relevant timestamp is older than 1 hour or not set
    # This prevents redundant DB writes when agents repeatedly view the same conversation
    agent_needs_update = @conversation.agent_last_seen_at.blank? || @conversation.agent_last_seen_at < 1.hour.ago
    return agent_needs_update unless assignee?

    # For assignees, check both timestamps - update if either is old
    assignee_needs_update = @conversation.assignee_last_seen_at.blank? || @conversation.assignee_last_seen_at < 1.hour.ago
    agent_needs_update || assignee_needs_update
  end
end
