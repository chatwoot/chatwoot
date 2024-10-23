class UpdateChatbotStatusColInConversation < ActiveRecord::Migration[7.0]
  def change
    remove_column :conversations, :chatbot_status, :string
    add_column :conversations, :chatbot_attributes, :jsonb, default: {}
  end
end
