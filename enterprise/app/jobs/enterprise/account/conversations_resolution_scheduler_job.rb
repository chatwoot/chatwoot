module Enterprise::Account::ConversationsResolutionSchedulerJob
  def perform
    super

    # TODO: remove this when response bot is remove in favor of captain
    resolve_response_bot_conversations

    # This is responsible for resolving captain conversations
    resolve_captain_conversations
  end

  private

  def resolve_response_bot_conversations
    # This is responsible for resolving response bot conversations
    Account.feature_response_bot.all.find_each(batch_size: 100) do |account|
      account.inboxes.each do |inbox|
        Captain::InboxPendingConversationsResolutionJob.perform_later(inbox) if inbox.response_bot_enabled?
      end
    end
  end

  def resolve_captain_conversations
    Integrations::Hook.where(app_id: 'captain').all.find_each(batch_size: 100) do |hook|
      next unless hook.enabled?

      inboxes = Inbox.where(id: hook.settings['inbox_ids'].split(','))
      inboxes.each do |inbox|
        Captain::InboxPendingConversationsResolutionJob.perform_later(inbox)
      end
    end
  end
end
