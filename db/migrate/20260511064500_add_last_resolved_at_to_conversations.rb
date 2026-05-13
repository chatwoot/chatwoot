class AddLastResolvedAtToConversations < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :last_resolved_at, :datetime, precision: nil
  end
end
