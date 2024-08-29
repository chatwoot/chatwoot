require 'http'
class ChatbotJob < ApplicationJob
  queue_as :high

  def perform(message, website_token, conversation)
    chatbot = Chatbot.find_by(website_token: website_token)
    conversation_id = conversation.id
    conversation = Conversation.find_by(id: conversation_id)
    return unless conversation.present? && chatbot.present? && chatbot.status == 'Enabled' && conversation.chatbot_status == 'Enabled'

    client_message = message[:content]
    HTTP.post(
      ENV.fetch('MICROSERVICE_URL', nil) + '/chatbot/query',
      form: { id: chatbot.id, account_id: chatbot.account_id, user_query: client_message, conversation_id: conversation_id },
      headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
    )
  end
end
