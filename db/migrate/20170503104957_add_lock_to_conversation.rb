class AddLockToConversation < ActiveRecord::Migration[5.0]
  def change
    add_column :conversations, :locked, :boolean, default: false
  end
end
