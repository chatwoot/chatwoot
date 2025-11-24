class AddPriorityToConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :conversations, :priority_score, :decimal, precision: 5, scale: 2, default: 0.0
    add_column :conversations, :priority_level, :integer, default: 0
    add_column :conversations, :priority_factors, :jsonb, default: {}

    add_index :conversations, :priority_score
    add_index :conversations, :priority_level
  end
end
