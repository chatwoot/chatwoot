class Notification::RemoveDuplicateNotificationJob < ApplicationJob
  queue_as :default
  def perform(notification)
    # Ensure the notification object is passed correctly
    return unless notification.is_a?(Notification)

    user_id = notification.user_id
    primary_actor_id = notification.primary_actor_id
    # Find and delete older notifications with the same user and primary_actor_id, excluding the new one
    Notification.where(user_id: user_id,
                       primary_actor_id: primary_actor_id)
                .where.not(id: notification.id)
                .delete_all
  end
end
