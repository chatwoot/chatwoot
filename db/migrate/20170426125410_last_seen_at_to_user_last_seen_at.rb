class LastSeenAtToUserLastSeenAt < ActiveRecord::Migration[5.0]
  def change
    rename_column :conversations, :last_seen_at, :user_last_seen_at
  end
end
