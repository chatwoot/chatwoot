class RemoveOldNotifications < ActiveRecord::Migration[6.0]
  def change
    Notification.where(notification_type: 'assigned_conversation_new_message').destroy_all
  end
end
