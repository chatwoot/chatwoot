class AddResolvedAtToConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :conversations, :resolved_at, :datetime
    add_index  :conversations, :resolved_at
  end
end
