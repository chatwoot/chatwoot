# Reads events off the connector's streams and hands them to the session dispatcher.
#
# Ordering is the whole point of the design: the connector puts every event of a
# session on the same shard, and exactly one consumer owns a shard at a time, so the
# events of one session are processed one at a time, in order, by one thread. That is
# why an event is dispatched inline instead of being turned into a job.
module Whatsapp::Connector::Consumer
  GROUP = 'chatwoot'.freeze

  # How the process is run: inside Sidekiq (the default), as its own process, or not at
  # all (for a deployment whose connector is served by another Chatwoot).
  def self.mode
    ENV.fetch('WHATSAPP_CONNECTOR_CONSUMER', 'sidekiq')
  end

  def self.enabled?
    Whatsapp::Connector.enabled? && mode != 'off'
  end

  def self.shard_key(shard)
    Whatsapp::Connector.key('events', shard)
  end

  # The largest event shard count the consumers have read on this Redis, which is how they
  # find the streams a re-shard retired. Named outside `events:<n>` and `consumer:*`, the
  # patterns the previous version scans for.
  def self.topology_key
    Whatsapp::Connector.key('consumers', 'topology')
  end

  def self.lease_key(shard)
    Whatsapp::Connector.key('events', shard, 'lease')
  end

  def self.cursor_key(session_id)
    Whatsapp::Connector.key('cursor', session_id)
  end

  def self.consumer_key(consumer_id)
    Whatsapp::Connector.key('consumer', consumer_id)
  end

  def self.dlq_key
    Whatsapp::Connector.key('dlq', 'events')
  end
end
