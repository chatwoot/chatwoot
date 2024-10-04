class CascadeConversationHandleTags < ActiveRecord::Migration[7.0]
  def change
    if foreign_key_exists?(:conversations, :conversation_handled_by_tags)
      remove_foreign_key :conversations, :conversation_handled_by_tags
    end

    if foreign_key_exists?(:users, :conversation_handled_by_tags)
      remove_foreign_key :users, :conversation_handled_by_tags
    end
  end
end
