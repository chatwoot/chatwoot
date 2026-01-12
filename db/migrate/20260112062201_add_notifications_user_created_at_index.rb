class AddNotificationsUserCreatedAtIndex < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :notifications, [:user_id, :created_at],
              name: 'idx_notifications_user_created_at',
              algorithm: :concurrently
  end
end
