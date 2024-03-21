class Notification::RemoveDuplicateNotificationJob < ApplicationJob
  queue_as :default

  def perform(notification)
    return unless notification.is_a?(Notification)

    user_id = notification.user_id
    primary_actor_id = notification.primary_actor_id

    # Find older notifications with the same user and primary_actor_id
    duplicate_notifications = Notification.where(user_id: user_id, primary_actor_id: primary_actor_id)
                                          .order(created_at: :desc)

    # Skip the first one (the latest notification) and destroy the rest
    duplicate_notifications.offset(1).each(&:destroy)
  end
end
