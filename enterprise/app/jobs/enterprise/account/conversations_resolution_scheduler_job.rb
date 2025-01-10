module Enterprise::Account::ConversationsResolutionSchedulerJob
  def perform
    super

    resolve_response_bot_conversations
  end

  private

  def resolve_response_bot_conversations
    Account.feature_response_bot.all.find_each(batch_size: 100) do |account|
      account.inboxes.each do |inbox|
        Captain::InboxPendingConversationsResolutionJob.perform_later(inbox) if inbox.captain_assistant.present?
      end
    end
  end
end
