class Notification::PushNotificationService
  include Rails.application.routes.url_helpers

  pattr_initialize [:notification!]

  def perform
    return unless user_subscribed_to_notification?

    notification_subscriptions.each do |subscription|
      send_browser_push(subscription)
      send_fcm_push(subscription)
    end
  end

  private

  delegate :user, to: :notification
  delegate :notification_subscriptions, to: :user
  delegate :notification_settings, to: :user

  def user_subscribed_to_notification?
    notification_setting = notification_settings.find_by(account_id: notification.account.id)
    return true if notification_setting.public_send("push_#{notification.notification_type}?")

    false
  end

  def conversation
    @conversation ||= notification.conversation
  end

  def push_message
    {
      title: notification.push_message_title,
      tag: "#{notification.notification_type}_#{conversation.display_id}",
      url: push_url
    }
  end

  def push_url
    app_account_conversation_url(account_id: conversation.account_id, id: conversation.display_id)
  end

  def send_browser_push?(subscription)
    ENV['VAPID_PUBLIC_KEY'] && subscription.browser_push?
  end

  def send_browser_push(subscription)
    return unless send_browser_push?(subscription)

    Webpush.payload_send(
      message: JSON.generate(push_message),
      endpoint: subscription.subscription_attributes['endpoint'],
      p256dh: subscription.subscription_attributes['p256dh'],
      auth: subscription.subscription_attributes['auth'],
      vapid: {
        subject: push_url,
        public_key: ENV['VAPID_PUBLIC_KEY'],
        private_key: ENV['VAPID_PRIVATE_KEY']
      },
      ssl_timeout: 5,
      open_timeout: 5,
      read_timeout: 5
    )
  rescue Webpush::ExpiredSubscription
    subscription.destroy!
  rescue Errno::ECONNRESET, Net::OpenTimeout, Net::ReadTimeout => e
    Rails.logger.info "Webpush operation error: #{e.message}"
  end

  def send_fcm_push(subscription)
    return unless ENV['FCM_SERVER_KEY']
    return unless subscription.fcm?

    fcm = FCM.new(ENV['FCM_SERVER_KEY'])
    response = fcm.send([subscription.subscription_attributes['push_token']], fcm_options)
    subscription.destroy! if JSON.parse(response[:body])['results']&.first&.keys&.include?('error')
  end

  def fcm_options
    {
      "notification": {
        "title": notification.notification_type.titleize,
        "body": notification.push_message_title
      },
      "data": { notification: notification.push_event_data.to_json },
      "collapse_key": "chatwoot_#{notification.primary_actor_type.downcase}_#{notification.primary_actor_id}"
    }
  end
end
