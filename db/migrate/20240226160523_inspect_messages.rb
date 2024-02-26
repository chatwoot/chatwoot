class InspectMessages < ActiveRecord::Migration[7.0]
  def change
    conversations = Conversation.where(display_id: [10525, 10527])
    conversations.each do |convo|
      puts "test_conversation_data: #{convo.attributes}"
      convo.messages.each do |msg|
        puts "test_message_data: #{msg.attributes}"
      end
    end
  end
end
