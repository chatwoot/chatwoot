# Keeps the Chatwoot Hub voice relay's list of this installation's phones in step with the
# subscriptions here: a token some subscription still holds is registered, any other is removed.
# The hub refuses a token another installation registered, until the hub team releases it.
class Voice::RelayDeviceSync
  pattr_initialize [:platform!, :token!]

  def perform
    return unless Voice::VoipPushConfig.new(report_partial: false).relayed?(platform.to_sym)

    method = held? ? :put : :delete
    ChatwootHub.voice_relay_request(method, 'devices', { platform: platform, token: token })
  end

  # The relay platform of a subscription's phone: iPhones by their VoIP token, Android phones
  # by their FCM token
  def self.platform_for(subscription)
    return 'apple' if subscription.apns_voip?

    'android' if subscription.fcm? && subscription.subscription_attributes['devicePlatform'].to_s.casecmp('android').zero?
  end

  private

  def held?
    NotificationSubscription.where(subscription_type: platform == 'apple' ? 'apns_voip' : 'fcm')
                            .exists?(["subscription_attributes->>'push_token' = ?", token])
  end
end
