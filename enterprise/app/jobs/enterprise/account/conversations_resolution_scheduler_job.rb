module Enterprise::Account::ConversationsResolutionSchedulerJob
  def perform
    super

    resolve_captain_conversations
  end

  private

  def resolve_captain_conversations
    CaptainInbox.all.find_each(batch_size: 100) do |captain_inbox|
      inbox = captain_inbox.inbox

      next if inbox.email?
      next if inbox.account.captain_disable_auto_resolve

      Captain::InboxPendingConversationsResolutionJob.perform_later(
        inbox
      )
    end
  end
end
