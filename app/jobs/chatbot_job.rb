require 'http'
class ChatbotJob < ApplicationJob
  queue_as :high

  def perform(message, website_token, conversation)
    microservice_url = URI.parse(ENV.fetch('MICROSERVICE_URL', nil))
    begin
      response = Net::HTTP.get_response(microservice_url)
      chatbot = Chatbot.find_by(website_token: website_token)
      conversation.update!(chatbot_attributes: { id: chatbot.id, status: 'Enabled' }) if conversation.chatbot_attributes == {}
      conversation_id = conversation.id
      conversation = Conversation.find_by(id: conversation_id)
      return unless conversation.present? && chatbot.present? && chatbot.status == 'Enabled' && conversation.chatbot_attributes['status'] == 'Enabled'

      client_message = message[:content]
      HTTP.post(
        ENV.fetch('MICROSERVICE_URL', nil) + '/chatbot/query',
        form: { id: chatbot.id, user_query: client_message, conversation_id: conversation_id },
        headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
      )
    rescue Errno::ECONNREFUSED => e
      # Handle connection refusal gracefully without marking the job as error
      Rails.logger.info "Connection refused: #{e.message}"
    rescue StandardError => e
      Rails.logger.info "An error occurred: #{e.message}"
    end
  end
end
