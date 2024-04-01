class Digitaltolk::CloseResolvedConversationService
  attr_accessor :account

  def initialize
    @account = Account.first
  end

  def perform
    close_chats!
    closed_emails!
  end

  private

  def conversations
    account.conversations
           .resolved
           .unclosed
           .joins(:messages)
           .where("messages.processed_message_content LIKE '%resolved%'")
  end

  def chat_conversations
    conversations.distinct.joins(:inbox).where(inboxes: { channel_type: 'Channel::WebWidget'})
                 .where.not(messages: { created_at: chat_span })
                 .limit(50)
  end

  def email_conversations
    conversations.distinct.joins(:inbox).where(inboxes: { channel_type: 'Channel::Email'})
                 .where.not(messages: { created_at: email_span })
                 .limit(50)
  end

  def closed_emails!
    email_conversations.each do |convo|
      convo.update(closed: true)
    end
  end

  def close_chats!
    chat_conversations.each do |convo|
      convo.update(closed: true)
    end
  end

  def chat_span
    (1.day.ago)..Time.current
  end

  def email_span
    (7.days.ago)..Time.current
  end
end