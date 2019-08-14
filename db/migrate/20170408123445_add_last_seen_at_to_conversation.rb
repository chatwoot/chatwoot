class AddLastSeenAtToConversation < ActiveRecord::Migration[5.0]
  def change
    add_column :conversations, :last_seen_at, :date
  end
end
