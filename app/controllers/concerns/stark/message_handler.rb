module Stark
  module MessageHandler
    extend ActiveSupport::Concern

    def handle_response(response)
      create_bot_response_with_image(current_conversation, response['content'], response['attachments']) if response['content'].present?
      process_action(event_data[:message], response['action']) if response['action'].present?
    end
    def create_bot_response_with_image(conversation, content, attachments)
      message = conversation.messages.new(
        content: content,
        message_type: :outgoing,
        content_type: 'text', 
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        sender: agent_bot
      )
    if attachments.present?
      attachments.each do |attachment|
        file = URI.parse(attachment).open
        filename = File.basename(attachment)
    
        message.attachments.build(
          account_id: message.account_id, 
          file_type: "image", 
          file: {
            io: file, filename: filename, content_type: "image"
          }
        )
      end
    end 
    
      message.save! 
    end
    

    def response_valid?(response)
      response.is_a?(Hash) && (response['content'].present? || response['action'].present?)
    end
  end
end
