class CascadeConversationHandleTags < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :conversation_handled_by_tags, :conversations
    remove_foreign_key :conversation_handled_by_tags, :users
  end
end
