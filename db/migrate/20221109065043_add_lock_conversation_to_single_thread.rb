class AddLockConversationToSingleThread < ActiveRecord::Migration[6.1]
  def change
    add_column :inboxes, :lock_to_single_conversation, :boolean, null: false, default: false
  end
end
