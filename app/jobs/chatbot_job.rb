require 'http'
class ChatbotJob < ApplicationJob
  queue_as :high

  def perform(message, website_token, conversation)
    microservice_url = URI.parse(ENV.fetch('MICROSERVICE_URL', nil))
    begin
      response = Net::HTTP.get_response(microservice_url)
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
    rescue Errno::ECONNREFUSED => e
      # Handle connection refusal gracefully without marking the job as error
      puts "Connection refused: #{e.message}"
    rescue StandardError => e
      # Handle other possible exceptions
      puts "An error occurred: #{e.message}"
    end
  end
end
