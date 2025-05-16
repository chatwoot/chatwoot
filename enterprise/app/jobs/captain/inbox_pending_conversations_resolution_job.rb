class Captain::InboxPendingConversationsResolutionJob < ApplicationJob
  queue_as :low

  def perform(inbox)
    # limiting the number of conversations to be resolved to avoid any performance issues
    Current.executed_by = inbox.captain_assistant
    resolvable_conversations = inbox.conversations.pending.where('last_activity_at < ? ', Time.now.utc - 1.hour).limit(Limits::BULK_ACTIONS_LIMIT)
    resolvable_conversations.each do |conversation|
      resolution_message = conversation.inbox.captain_assistant.config['resolution_message']
      conversation.messages.create!(
        {
          message_type: :outgoing,
          account_id: conversation.account_id,
          inbox_id: conversation.inbox_id,
          content: resolution_message || I18n.t('conversations.activity.auto_resolution_message')
        }
      )
      conversation.resolved!
    ensure
      Current.reset
    end
  end
end
