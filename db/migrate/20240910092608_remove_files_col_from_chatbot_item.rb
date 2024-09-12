class RemoveFilesColFromChatbotItem < ActiveRecord::Migration[7.0]
  def change
    drop_table :chatbot_items
    remove_column :conversations, :chatbot_status, :string
  end
end
