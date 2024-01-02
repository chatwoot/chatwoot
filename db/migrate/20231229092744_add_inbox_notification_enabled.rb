class AddInboxNotificationEnabled < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :push_notification_enabled, :boolean, default: true
  end
end
