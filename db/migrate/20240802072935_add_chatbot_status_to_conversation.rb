class AddChatbotStatusToConversation < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :chatbot_status, :string, default: 'Enabled'
  end
end
