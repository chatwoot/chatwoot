class AddDraftMessageToConversation < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :draft_message_content, :text, null: true
  end
end
