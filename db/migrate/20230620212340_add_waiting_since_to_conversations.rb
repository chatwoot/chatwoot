class AddWaitingSinceToConversations < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :waiting_since, :datetime
    add_index :conversations, :waiting_since
  end
end
