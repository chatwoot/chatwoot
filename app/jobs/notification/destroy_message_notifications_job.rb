class Notification::DestroyMessageNotificationsJob < ApplicationJob
  queue_as :low

  def perform(notification)
    # Ensure the notification object is passed correctly
    return unless notification.is_a?(Notification)

    # Destroy all the existing notifications where primary actor is Message and do it in batches
    Notification.where(user_id: notification.user_id)
                .where(primary_actor_type: 'Message')
                .find_each(batch_size: 100, &:destroy)
  end
end
