module Enterprise::Account::ConversationsResolutionSchedulerJob
  def perform
    super
    Account.feature_response_bot.all.find_each(batch_size: 100) do |account|
      account.inboxes.each do |inbox|
        ResponseBot::InboxPendingConversationsResolutionJob.perform_later(inbox) if inbox.response_bot_enabled?
      end
    end
  end
end
