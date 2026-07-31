class Notification::RemoveDuplicateNotificationJob < ApplicationJob
  queue_as :default
  BOT_HANDOFF_EVENT_IDS_META_KEY = 'bot_handoff_event_ids'.freeze
  private_constant :BOT_HANDOFF_EVENT_IDS_META_KEY

  def perform(notification)
    return unless notification.is_a?(Notification)

    user_id = notification.user_id
    primary_actor_id = notification.primary_actor_id

    # Find older notifications with the same user and primary_actor_id
    duplicate_notifications = Notification.where(user_id: user_id, primary_actor_id: primary_actor_id)
                                          .order(created_at: :desc)
    latest_notification = duplicate_notifications.first

    # Skip the first one (the latest notification) and destroy the rest
    duplicate_notifications.offset(1).each do |duplicate_notification|
      preserve_bot_handoff_event_ids(latest_notification, duplicate_notification)
      duplicate_notification.destroy
    end
  end

  private

  def preserve_bot_handoff_event_ids(notification, duplicate_notification)
    event_ids = bot_handoff_event_ids(notification) | bot_handoff_event_ids(duplicate_notification)
    return if event_ids.blank?

    notification.update!(meta: notification.meta.to_h.merge(BOT_HANDOFF_EVENT_IDS_META_KEY => event_ids))
  end

  def bot_handoff_event_ids(notification)
    notification.meta.to_h[BOT_HANDOFF_EVENT_IDS_META_KEY].to_a
  end
end
