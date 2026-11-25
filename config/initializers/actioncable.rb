# frozen_string_literal: true

require 'action_cable/subscription_adapter/redis'

ActionCable::SubscriptionAdapter::Redis.redis_connector = lambda do |config|
  # For supporting GCP Memorystore where `client` command is disabled.
  # You can configure the following ENV variable to get your installation working.
  # ref:
  # https://github.com/mperham/sidekiq/issues/3518#issuecomment-595611673
  # https://github.com/redis/redis-rb/issues/767
  # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75173
  # https://github.com/rails/rails/blob/4a23cb3415eac03d76623112576559a722d1f23d/actioncable/lib/action_cable/subscription_adapter/base.rb#L30
  config[:id] = nil if ENV['REDIS_DISABLE_CLIENT_COMMAND'].present?

  # Exclude `:reconnect_attempts` so the publisher connection doesn't park threads
  # on the full backoff during a Redis outage; the listener reads it from cable.yml.
  Redis.new(config.except(:adapter, :channel_prefix, :reconnect_attempts))
end

# Stock Rails gives up on the subscriber connection once `reconnect_attempts` is spent: the
# listener thread exits, stays memoized, and every later subscribe waits on it forever, so the
# worker delivers no broadcast and confirms no subscription until it restarts (rails/rails#58939).
# A Redis outage longer than the budget in cable.yml did exactly that to two of three Puma workers.
module ActionCableRedisListenerRecovery
  # `shutdown` waits for the listener thread to end, which a retry loop with no limit would never do.
  def shutdown
    @shutting_down = true
    super
  end

  def remove_channel(channel)
    # While disconnected no SUBSCRIBE is in flight, so the pending confirmations of a channel that
    # leaves can go now instead of piling up, with their subscribers, until Redis comes back.
    @subscription_lock.synchronize { @subscribe_callbacks.delete(channel) unless @subscribed_client }
    super
  end

  private

  # Keeps retrying past the configured list, at its last interval, until the server shuts down.
  def retry_connecting?
    @reconnect_attempt += 1
    interval = @reconnect_attempts[@reconnect_attempt - 1] || @reconnect_attempts.last || 0
    Rails.logger.warn("[ActionCable] Redis subscriber connection lost, retry #{@reconnect_attempt} in #{interval}s")
    sleep(interval) if interval.positive?
    # A shutdown that arrived during the sleep has already queued its teardown ahead of the resubscribe.
    !@shutting_down
  end

  # Stock `reset` also drops the pending subscribe confirmations, and the reconnect resubscribes
  # those channels without them, so a subscription made during the outage would never be confirmed.
  def reset
    @subscription_lock.synchronize do
      @subscribed_client = nil
      @when_connected.clear
    end
  end

  # Runs right after a reconnect, under the subscription lock and before any reply is read. The new
  # connection answers each subscribed channel once, so only the newest pending confirmation of a
  # channel still subscribed may stay: older ones, and those of channels that left, belong to
  # subscribers that are gone and would otherwise take the reply meant for the current one.
  def resubscribe
    channels = @sync.synchronize { @subscribers.keys }
    @subscribe_callbacks.select! { |channel, _| channels.include?(channel) }
    @subscribe_callbacks.transform_values! { |callbacks| callbacks.last(1) }
    super
    reconnect_clients
  end

  # Redis pub/sub keeps nothing, so whatever was broadcast while the listener was cut off is gone, and
  # the browsers never noticed: their WebSocket to this process stayed up the whole time. Asking them
  # to reconnect runs the dashboard's reconnect path, which refetches what the outage hid. Posted to
  # the event loop because closing a connection unsubscribes it, which takes the lock held here. The
  # list is copied first: a close handshake that completes mid-loop removes its connection from it.
  def reconnect_clients
    @event_loop.post do
      @adapter.server.connections.dup.each { |connection| connection.close(reason: 'pubsub_reconnected', reconnect: true) }
    end
  end
end

ActionCable::SubscriptionAdapter::Redis::Listener.prepend(ActionCableRedisListenerRecovery)
