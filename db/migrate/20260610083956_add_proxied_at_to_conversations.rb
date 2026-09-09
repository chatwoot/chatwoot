class AddProxiedAtToConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :conversations, :proxied_at, :datetime
    add_index :conversations, :proxied_at
  end
end
