class RemoveNotificationsWithMessagePrimaryActor < ActiveRecord::Migration[7.0]
  def change
    Migration::RemoveMessageNotifications.perform_later
  end
end
