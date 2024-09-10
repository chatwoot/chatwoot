class RemoveFilesColFromChatbotItem < ActiveRecord::Migration[7.0]
  def change
    remove_column :chatbot_items, :files, :jsonb
  end
end
