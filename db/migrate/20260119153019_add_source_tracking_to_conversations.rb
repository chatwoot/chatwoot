class AddSourceTrackingToConversations < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :source_type, :integer, default: 0, null: false
    add_column :conversations, :source_metadata, :jsonb, default: {}

    add_index :conversations, :source_type
    add_index :conversations, :source_metadata, using: :gin
  end
end
