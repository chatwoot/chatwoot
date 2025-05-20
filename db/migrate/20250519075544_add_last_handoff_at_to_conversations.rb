class AddLastHandoffAtToConversations < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :last_handoff_at, :datetime
    add_index :conversations, :last_handoff_at
  end
end
