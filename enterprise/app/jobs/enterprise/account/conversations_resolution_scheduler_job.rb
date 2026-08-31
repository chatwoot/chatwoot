module Enterprise::Account::ConversationsResolutionSchedulerJob
  def perform
    super

    resolve_captain_conversations
  end

  private

  def resolve_captain_conversations
    CaptainInbox.all.find_each(batch_size: 100) do |captain_inbox|
      inbox = captain_inbox.inbox
      assistant = captain_inbox.captain_assistant

      next unless inbox.captain_inactivity_resolution_supported?
      next if assistant.blank? || assistant.inactive_conversation_resolution_disabled?

      Captain::InboxPendingConversationsResolutionJob.perform_later(
        inbox
      )
    end
  end
end
