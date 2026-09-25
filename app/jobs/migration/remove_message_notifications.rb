# Delete migration and spec after 2 consecutive releases.
class Migration::RemoveMessageNotifications < ApplicationJob
  queue_as :within_10_minutes

  def perform
    Notification.where(primary_actor_type: 'Message').in_batches(of: 100).delete_all
  end
end
