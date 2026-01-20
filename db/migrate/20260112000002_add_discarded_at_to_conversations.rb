class AddDiscardedAtToConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :conversations, :discarded_at, :datetime
    add_index :conversations, :discarded_at
  end
end
