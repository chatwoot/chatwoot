# The transport to the Go connector (the `native` provider).
#
# Chatwoot and the connector share the Redis that is already on the machine: commands
# go on a per-session stream, events come back on sharded streams, and RPC answers on a
# short-lived list. Nothing about this is namespaced by Redis::Namespace: the keys are
# read and written by another process, so they are plain, prefixed keys.
module Whatsapp::Connector
  # Kept configurable on both sides for the rare deployment that shares one Redis
  # between two Chatwoot installations.
  def self.prefix
    ENV.fetch('WHATSAPP_CONNECTOR_REDIS_PREFIX', 'wa:')
  end

  def self.key(*parts)
    "#{prefix}#{parts.join(':')}"
  end

  def self.enabled?
    ENV.fetch('WHATSAPP_CONNECTOR_ENABLED', 'true') != 'false'
  end

  # How many event streams the connector fans sessions across, as this installation is
  # configured. Only the answer until a connector has run: it publishes the count it is
  # actually using, and that one wins.
  #
  # The default tracks the connector's own `WAC_EVENT_SHARDS`, which is what an
  # installation that sets neither side ends up running. They drifted once, and the cost
  # was not the consumer, which follows what is published: it was the database pool,
  # sized from this number in `config/database.yml`, reserving half the connections the
  # consumer threads would ask for.
  def self.event_shards
    ENV.fetch('WHATSAPP_CONNECTOR_EVENT_SHARDS', '16').to_i
  end

  # The count the running connector publishes, which is what decides where a session's
  # events land. Reading fewer than it publishes would leave whole streams unconsumed and
  # the inboxes sharded onto them silently deaf.
  # What the running connector says it publishes, or nil when it has not said anything
  # yet. The difference matters to anyone deciding whether the count has changed: the
  # local setting is a guess made before the connector was reachable, and taking it for
  # an announcement makes the connector's first real one look like a re-shard.
  def self.published_shards(redis)
    advertised = redis.hget(key('meta'), 'event_shards').to_i
    return nil unless advertised.positive?

    configured = event_shards
    warn_on_shard_drift(advertised, configured) unless advertised == configured
    advertised
  end

  def self.advertised_shards(redis)
    published_shards(redis) || event_shards
  end

  # Following the connector is right either way. Above the configured number it also
  # means the database pool, sized from that number, has no connections reserved for the
  # extra threads.
  def self.warn_on_shard_drift(advertised, configured)
    room = advertised > configured ? ', raise WHATSAPP_CONNECTOR_EVENT_SHARDS to match so the database pool has room' : ''
    Rails.logger.warn(
      "[WHATSAPP CONNECTOR] the connector publishes #{advertised} event shards, this is configured for " \
      "#{configured}; following the connector#{room}"
    )
  end
end
