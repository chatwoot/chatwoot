class AddIndexesForPerformanceImprovements < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :conversations, :last_activity_at, algorithm: :concurrently
    add_index :messages, [:conversation_id, :created_at], order: { created_at: :desc }, algorithm: :concurrently
  end
end
