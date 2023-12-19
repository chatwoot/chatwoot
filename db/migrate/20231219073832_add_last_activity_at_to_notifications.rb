class AddLastActivityAtToNotifications < ActiveRecord::Migration[7.0]
  def change
    add_column :notifications, :last_activity_at, :datetime, default: nil
    add_index :notifications, :last_activity_at
  end
end
