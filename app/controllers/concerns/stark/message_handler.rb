module Stark
  module MessageHandler
    extend ActiveSupport::Concern

    def handle_response(response)
      create_bot_response_message(current_conversation, response['content']) if response['content'].present?
      process_action(event_data[:message], response['action']) if response['action'].present?
    end

    def create_bot_response_message(conversation, content)
      conversation.messages.create!(
        content: content,
        message_type: :outgoing,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        sender: agent_bot
      )
    end

    def response_valid?(response)
      response.is_a?(Hash) && (response['content'].present? || response['action'].present?)
    end
  end
end
