class AddNotificationsPerformanceIndex < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    # Add composite index to optimize notification count queries
    # This covers the common query pattern: WHERE user_id = ? AND account_id = ? AND snoozed_until IS NULL AND read_at IS NULL
    add_index :notifications, [:user_id, :account_id, :snoozed_until, :read_at],
              name: 'idx_notifications_performance',
              algorithm: :concurrently
  end
end
