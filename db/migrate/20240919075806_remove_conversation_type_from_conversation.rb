class RemoveConversationTypeFromConversation < ActiveRecord::Migration[7.0]
  def change
    remove_column :conversations, :conversation_type, :integer
  end
end
