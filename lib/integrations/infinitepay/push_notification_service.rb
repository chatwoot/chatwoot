# frozen_string_literal: true

class Integrations::Infinitepay::PushNotificationService
  pattr_initialize [:payment_link!, :notification_payload!]

  def perform
    return unless push_only_enabled?

    browser_push_subscriptions.find_each do |subscription|
      send_browser_push(subscription)
    end
  end

  private

  def account
    payment_link.account
  end

  def push_only_enabled?
    ActiveModel::Type::Boolean.new.cast(account.custom_attributes&.dig('infinitepay_push_only'))
  end

  def browser_push_subscriptions
    NotificationSubscription
      .browser_push
      .joins(user: :account_users)
      .where(account_users: { account_id: account.id })
      .includes(:user)
      .distinct
  end

  def browser_push_payload(subscription)
    {
      message: JSON.generate(notification_payload),
      endpoint: subscription.subscription_attributes['endpoint'],
      p256dh: subscription.subscription_attributes['p256dh'],
      auth: subscription.subscription_attributes['auth'],
      vapid: {
        subject: notification_payload[:url],
        public_key: VapidService.public_key,
        private_key: VapidService.private_key
      },
      ssl_timeout: 5,
      open_timeout: 5,
      read_timeout: 5
    }
  end

  def send_browser_push(subscription)
    return if VapidService.public_key.blank?

    WebPush.payload_send(**browser_push_payload(subscription))
    Rails.logger.info(
      "[INFINITEPAY-PUSH] Browser push sent to #{subscription.user.email} for payment_link=#{payment_link.id}"
    )
  rescue StandardError => e
    handle_browser_push_error(e, subscription)
  end

  def handle_browser_push_error(error, subscription)
    case error
    when WebPush::ExpiredSubscription, WebPush::InvalidSubscription, WebPush::Unauthorized
      Rails.logger.info "[INFINITEPAY-PUSH] WebPush subscription expired: #{error.message}"
      subscription.destroy!
    when WebPush::TooManyRequests
      Rails.logger.warn(
        "[INFINITEPAY-PUSH] WebPush rate limited for #{subscription.user.email} on account #{account.id}: #{error.message}"
      )
    when Errno::ECONNRESET, Net::OpenTimeout, Net::ReadTimeout
      Rails.logger.error "[INFINITEPAY-PUSH] WebPush operation error: #{error.message}"
    else
      ChatwootExceptionTracker.new(error, account: account).capture_exception
    end
  end
end