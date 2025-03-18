class Digitaltolk::CloseResolvedConversationService
  attr_accessor :account

  def initialize(account_id)
    @account = Account.find_by(id: account_id)
  end

  def perform
    return if @account.blank?

    close_chats!
    closed_emails!
  end

  private

  def conversations
    account.conversations
           .resolved
           .unclosed
  end

  def chat_inboxes_ids
    account.inboxes.where(channel_type: 'Channel::WebWidget').select(:id)
  end

  def email_inboxes_ids
    account.inboxes.where(channel_type: 'Channel::Email').select(:id)
  end

  def chat_conversations
    conversations.where(inbox_id: chat_inboxes_ids).where('last_activity_at < ?', stale_chat_age).limit(50)
  end

  def email_conversations
    conversations.where(inbox_id: email_inboxes_ids).where('last_activity_at < ?', stale_email_age).limit(50)
  end

  def closed_emails!
    email_conversations.each do |convo|
      next if convo.closed?

      convo.update(closed: true)
    end
  end

  def close_chats!
    chat_conversations.each do |convo|
      next if convo.closed?

      convo.update(closed: true)
    end
  end

  def stale_chat_age
    1.day.ago
  end

  def stale_email_age
    7.days.ago
  end
end
