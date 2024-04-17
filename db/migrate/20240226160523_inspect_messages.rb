class InspectMessages < ActiveRecord::Migration[7.0]
  def change
    conversations = Conversation.where(display_id: [10_525, 10_527])
    conversations.each do |convo|
      Rails.logger.debug { "test_conversation_data: #{convo.attributes}" }
      convo.messages.each do |msg|
        Rails.logger.debug "test_message_data: #{msg.attributes}"
      end
    end
  end
end
