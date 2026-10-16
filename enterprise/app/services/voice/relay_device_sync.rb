# Keeps the Chatwoot Hub voice relay's list of this installation's phones in step with the
# subscriptions here: a token some subscription still holds is registered, any other is removed.
# Each request carries the revision the change was made at, and the hub ignores one older than
# the last it applied, so requests that overtake each other settle on the latest change. The hub
# refuses a token another installation registered, until the hub team releases it.
#
# The outcome of each phone's latest registration is kept for the Super Admin diagnostics.
class Voice::RelayDeviceSync
  STATES_KEY = 'VOICE_RELAY_DEVICE_STATES'.freeze

  pattr_initialize [:platform!, :token!, :revision!]

  def perform
    return unless Voice::VoipPushConfig.new(report_partial: false).relayed?(platform.to_sym)

    held? ? register : remove
  end

  # The revision for a change made now
  def self.revision = (Time.current.to_r * 1_000_000).to_i

  # 'registered', 'conflict' when another installation holds the token, 'rejected' when the hub
  # refused the relay secret, 'failed' when the hub could not be reached, or nil before the hub has answered
  def self.state(platform, token) = Redis::Alfred.hget(STATES_KEY, state_field(platform, token))

  def self.record_state(platform, token, state) = Redis::Alfred.hset(STATES_KEY, state_field(platform, token), state)

  def self.state_field(platform, token) = "#{platform}:#{Digest::SHA256.hexdigest(token)}"

  # The relay platform of a subscription's phone: iPhones by their VoIP token, Android phones
  # by their FCM token
  def self.platform_for(subscription)
    return 'apple' if subscription.apns_voip?

    'android' if subscription.fcm? && subscription.subscription_attributes['devicePlatform'].to_s.casecmp('android').zero?
  end

  private

  def register
    request(:put)
    self.class.record_state(platform, token, 'registered')
  rescue RestClient::Conflict, RestClient::Unauthorized => e
    self.class.record_state(platform, token, e.is_a?(RestClient::Conflict) ? 'conflict' : 'rejected')
    raise
  end

  def remove
    request(:delete)
    Redis::Alfred.with { |redis| redis.hdel(STATES_KEY, self.class.state_field(platform, token)) }
  end

  def request(method)
    ChatwootHub.voice_relay_request(method, 'devices', { platform: platform, token: token, revision: revision })
  end

  def held?
    NotificationSubscription.where(subscription_type: platform == 'apple' ? 'apns_voip' : 'fcm')
                            .exists?(["subscription_attributes->>'push_token' = ?", token])
  end
end
