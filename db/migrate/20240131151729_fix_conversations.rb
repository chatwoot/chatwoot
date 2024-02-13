class FixConversations < ActiveRecord::Migration[7.0]
  def change
    # webflow_email = '{{email}}@loopia.invalid'
    # messages = Message.where("content_attributes::text LIKE '%#{webflow_email}%'")
    # conversations = Conversation.where(id: messages.pluck(:conversation_id).uniq)

    # puts "fixingconversation: #{conversations.count}, #{messages.count}"
    # conversations.each do |conversation|
    #   Digitaltolk::FixInvalidConversation.new(conversation).call
    # end
  end
end
