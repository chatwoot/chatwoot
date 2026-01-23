class AddResolvedAtToConversations < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :conversations, :resolved_at, :datetime
    add_index :conversations, :resolved_at, algorithm: :concurrently
  end
end
