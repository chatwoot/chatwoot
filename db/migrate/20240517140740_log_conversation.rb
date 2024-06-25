class LogConversation < ActiveRecord::Migration[7.0]
  def change
    conversation = Conversation.find_by(display_id: 33_053)

    return unless conversation.present?

    puts 'logging conversation'
    puts conversation.attributes
    conversation.messages.each do |msg|
      puts msg.attributes
    end
  end
end
