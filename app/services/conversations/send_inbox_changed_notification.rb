class Conversations::SendInboxChangedNotification
  def self.call(conversation, old_inbox, new_inbox)
    conversation.messages.create!(
      account_id: conversation.account_id,
      inbox_id: new_inbox.id,
      message_type: :activity,
      content: "Inbox изменён с #{old_inbox.name} на #{new_inbox.name}"
    )
  rescue StandardError => e
    Rails.logger.error("[QUEUE][notify_inbox_changed][conv=#{conversation.id}] Error: #{e.message}")
    ChatwootExceptionTracker.new(e, account: conversation.account).capture_exception
  end
end
