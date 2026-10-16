# Keeps the Chatwoot Hub voice relay's list of this installation's phones in step with the
# subscriptions here: a token some subscription still holds is registered, any other is removed.
# Each request carries the revision the change was made at, and the hub ignores one older than
# the last it applied, so requests that overtake each other settle on the latest change. The hub
# refuses a token another installation registered, until the hub team releases it.
#
# The outcome of each phone's latest registration is kept for the Super Admin diagnostics, with
# its revision, so an outcome for an older change arriving late does not replace a newer one.
class Voice::RelayDeviceSync
  STATES_KEY = 'VOICE_RELAY_DEVICE_STATES'.freeze

  # Attempts at writing an outcome while other writes to the states keep changing it
  RECORD_ATTEMPTS = 3

  pattr_initialize [:platform!, :token!, :revision!]

  def perform
    return unless Voice::VoipPushConfig.new(report_partial: false).relayed?(platform.to_sym)

    held? ? register : remove
  end

  # The revision for a change made now
  def self.revision = (Time.current.to_r * 1_000_000).to_i

  # 'registered', 'conflict' when another installation holds the token, 'rejected' when the hub
  # refused the relay secret, 'failed' when the hub could not be reached, or nil before the hub has
  # answered and once the token is removed
  def self.state(platform, token)
    state = Redis::Alfred.hget(STATES_KEY, state_field(platform, token))&.split(':', 2)&.last
    state unless state == 'removed'
  end

  # Sets the token's field to "revision:state" unless it holds a newer revision, under WATCH so a
  # write in between makes it read again
  def self.record_state(platform, token, revision, state)
    field = state_field(platform, token)
    Redis::Alfred.with do |redis|
      RECORD_ATTEMPTS.times do
        written = redis.watch(STATES_KEY) do
          current = redis.hget(STATES_KEY, field)
          next redis.unwatch && :stale if current && current.to_i > revision.to_i

          redis.multi { |transaction| transaction.hset(STATES_KEY, field, "#{revision}:#{state}") }
        end
        break unless written.nil?
      end
    end
  end

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
    self.class.record_state(platform, token, revision, 'registered')
  rescue RestClient::Conflict, RestClient::Unauthorized => e
    self.class.record_state(platform, token, revision, e.is_a?(RestClient::Conflict) ? 'conflict' : 'rejected')
    raise
  end

  def remove
    request(:delete)
    self.class.record_state(platform, token, revision, 'removed')
  end

  def request(method)
    ChatwootHub.voice_relay_request(method, 'devices', { platform: platform, token: token, revision: revision })
  end

  def held?
    NotificationSubscription.where(subscription_type: platform == 'apple' ? 'apns_voip' : 'fcm')
                            .exists?(["subscription_attributes->>'push_token' = ?", token])
  end
end
