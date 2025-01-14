module Enterprise::Account::ConversationsResolutionSchedulerJob
  def perform
    super

    resolve_captain_conversations
  end

  private

  def resolve_captain_conversations
    CaptainInbox.all.find_each(batch_size: 100) do |captain_inbox|
      Captain::InboxPendingConversationsResolutionJob.perform_later(captain_inbox.inbox)
    end
  end
end
