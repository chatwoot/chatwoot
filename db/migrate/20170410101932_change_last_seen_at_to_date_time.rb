class ChangeLastSeenAtToDateTime < ActiveRecord::Migration[5.0]
  def change
    change_column :conversations, :last_seen_at, :datetime
  end
end
