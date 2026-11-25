# Records how far up the WhatsApp connector's event streams go, for the installations that
# re-sharded before the consumers started recording it themselves (fazer-ai/chatwoot#865).
# The consumer drains a retired stream only up to `wa:consumers:topology`, and on those
# installations nothing had written it, so a retired stream that still held events would
# never be read.
#
# This is the one place that looks for the streams by pattern, once per installation, at
# deploy: the consumer stopped doing it on every tick because walking the shared Redis cost
# it most of its CPU (#862). Only streams count: lease keys share the prefix.
#
# Run again by hand: Migration::WhatsappConnectorTopologyJob.perform_now
class Migration::WhatsappConnectorTopologyJob < ApplicationJob
  queue_as :async_database_migration

  def perform
    redis = Redis.new(Redis::Config.app)
    shards = redis.scan_each(match: Whatsapp::Connector::Consumer.shard_key('*'), type: 'stream', count: 1000)
                  .filter_map { |key| key[/:(\d+)\z/, 1]&.to_i }
    return if shards.empty?

    recorded = redis.eval(Whatsapp::Connector::Consumer::ShardMap::RECORD_TOPOLOGY,
                          keys: [Whatsapp::Connector::Consumer.topology_key], argv: [shards.max + 1])
    Rails.logger.info("[WHATSAPP CONNECTOR] event stream topology recorded at #{recorded} shards")
  ensure
    redis&.close
  end
end
