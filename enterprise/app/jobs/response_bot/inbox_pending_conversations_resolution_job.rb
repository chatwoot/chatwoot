class ResponseBot::InboxPendingConversationsResolutionJob < ApplicationJob
  queue_as :low

  def perform(inbox)
    # limiting the number of conversations to be resolved to avoid any performance issues
    resolvable_conversations = inbox.conversations.pending.where('last_activity_at < ? ', Time.now.utc - 1.hour).limit(Limits::BULK_ACTIONS_LIMIT)
    resolvable_conversations.each do |conversation|
      conversation.messages.create!(
        {
          message_type: :outgoing,
          account_id: conversation.account_id,
          inbox_id: conversation.inbox_id,
          content: 'Resolving the conversation as it has been inactive for a while. Please start a new conversation if you need further assistance.'
        }
      )
      conversation.resolved!
    end
  end
end
