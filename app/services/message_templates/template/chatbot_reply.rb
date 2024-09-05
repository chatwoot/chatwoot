class MessageTemplates::Template::ChatbotReply
  pattr_initialize [:conversation!]

  def perform(bot_message)
    ActiveRecord::Base.transaction do
      conversation.messages.create!(chatbot_message_in_chatbox(bot_message))
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: conversation.account).capture_exception
    true
  end

  private

  delegate :contact, :account, to: :conversation
  delegate :inbox, to: :message

  def chatbot_message_in_chatbox(bot_message)
    content = bot_message
    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :template,
      content: content
    }
  end
end
