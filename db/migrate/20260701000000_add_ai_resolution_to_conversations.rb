class AddAiResolutionToConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :conversations, :resolved_by_ai, :boolean, default: false
    add_column :conversations, :ai_resolution_confidence, :float
    add_column :conversations, :ai_resolved_at, :datetime
    add_index :conversations, :resolved_by_ai
  end
end
