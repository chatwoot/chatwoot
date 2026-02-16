class AddLastTriagedAtToConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :conversations, :last_triaged_at, :datetime
  end
end
