class BaseListener
  include Singleton

  def extract_conversation_and_account(event)
    conversation = event.data[:conversation]
    [conversation, conversation.account, event.timestamp]
  end

  def extract_message_and_account(event)
    message = event.data[:message]
    [message, message.account, event.timestamp]
  end
end
