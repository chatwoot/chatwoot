class AddAbandonedAtToConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :conversations, :abandoned_at, :datetime
    add_index :conversations, :abandoned_at
  end
end
