# Which event streams this consumer should be reading right now.
#
# The count comes from the running connector, and is then fixed for the life of this
# process. It has to be: the connector re-maps sessions across the streams when it
# changes, so a session's older events sit on the stream it used to hash to while its
# newer ones arrive on the one it hashes to now, and whichever worker gets ahead pushes
# the session cursor past what the other has not reached yet.
#
# There is no way to follow that safely while running, and no subset of the streams that
# is safe to keep reading either. Waiting for the old mapping to finish only works when
# the streams it used stop being written to, and they generally do not: 2 to 4 leaves the
# old events on 0 and 1, which keep receiving new ones, and 8 to 6 moves sessions between
# streams that both survive. So a count that changes underneath stops this consumer
# instead of steering it, and it stays stopped until someone restarts it.
#
# What is still followed is the tail of a previous topology: streams above the current
# range that a restart inherited. Those really have stopped being written to, so they
# drain, and while they still hold work they are all this consumer reads, in case a
# session moved off them.
class Whatsapp::Connector::Consumer::ShardMap
  Consumer = Whatsapp::Connector::Consumer

  # Keeps the largest count it is given, and answers with whatever is largest now. It
  # writes only when the count grows: every consumer runs this on every tick, and the
  # topology changes only on a re-shard.
  RECORD_TOPOLOGY = <<~LUA.freeze
    local recorded = tonumber(redis.call('get', KEYS[1]) or '0')
    local count = tonumber(ARGV[1])
    if count > recorded then
      redis.call('set', KEYS[1], count)
      return count
    end
    return recorded
  LUA
  # How often a stopped consumer repeats itself, in supervisor ticks. A process that has
  # stopped reading must not also go quiet, and the state only clears on a restart.
  REMINDER_TICKS = 60

  def initialize(redis)
    @redis = redis
    @halted = false
    @ticks_while_halted = 0
  end

  # Whether this consumer has given up on the mapping it started with. Nothing clears it
  # but a restart, and while it is set the consumer reads nothing at all.
  def halted?
    @halted
  end

  def shards
    return nothing if moved_under_us?

    count = @mapping_size || Whatsapp::Connector.event_shards
    retired = retired_with_work(count)
    return (0...count).to_a if retired.empty?

    Rails.logger.warn("[WHATSAPP CONNECTOR] draining retired shards #{retired.join(', ')} before reading the rest")
    retired
  end

  private

  # True once the connector has published a count other than the one this process started
  # on. It never goes back: by then the streams have already been re-mapped, and only a
  # restart on the new count can read them in order again.
  def moved_under_us?
    return true if @halted

    published = Whatsapp::Connector.published_shards(@redis)
    # Nothing published yet: the connector has not started, or is between restarts. The
    # local setting stands in meanwhile but is not frozen, because freezing on a guess
    # and then meeting the connector's real count reads exactly like a hot re-shard, and
    # would stop a consumer whose only mistake was booting first.
    return false if published.nil?

    @mapping_size ||= published
    return false if published == @mapping_size

    @halted = true
    refuse_hot_change(published)
    true
  end

  # Nothing at all, rather than the range this process started with. Keeping the old
  # numeric range does not keep the old mapping: after 8 to 6, a session's older events
  # sit on 7 while its newer ones arrive on 2, both inside the old range, and the worker
  # on 2 would push the session cursor past what the worker on 7 has not reached.
  def nothing
    @ticks_while_halted += 1
    remind if (@ticks_while_halted % REMINDER_TICKS).zero?
    []
  end

  # Loud, because it needs a person: the connector has to stop, the consumers have to
  # finish what is on the streams, and then everything restarts on the new count.
  def refuse_hot_change(advertised)
    @ticks_while_halted = 0
    Rails.logger.error(
      "[WHATSAPP CONNECTOR] the connector now publishes #{advertised} event shards and this consumer was reading " \
      "#{@mapping_size}. Re-sharding while running reorders the sessions that moved, so this consumer has stopped " \
      'reading: stop the connector, let the consumers drain, and restart them on the new count.'
    )
  end

  def remind
    Rails.logger.error(
      '[WHATSAPP CONNECTOR] this consumer is still stopped after the connector changed its event shard count. ' \
      'Nothing is being read until it is restarted.'
    )
  end

  def retired_with_work(advertised)
    retired(advertised).select { |shard| backlog?(shard) }
  end

  # The streams of a previous, larger topology that are still there. On an installation
  # that never re-sharded the range is empty and this is one round trip.
  #
  # The range comes from the largest count any consumer has read here, which each of them
  # records as it goes (and which the deploy that introduced the record seeded from the
  # streams already there, Migration::WhatsappConnectorTopologyJob), and not from looking
  # for the pattern: a SCAN for a pattern walks
  # every key in the Redis the installation shares, and this runs on every tick. Nor can
  # it stop at the first stream that is missing, because the connector writes a stream
  # only once a session lands on it, so a retired stream with work can sit above one that
  # was never created.
  def retired(advertised)
    largest = @redis.eval(RECORD_TOPOLOGY, keys: [Consumer.topology_key], argv: [advertised]).to_i
    (advertised...largest).select { |shard| @redis.exists?(Consumer.shard_key(shard)) }
  end

  # Pending entries, or entries still sitting past where the group stopped.
  def backlog?(shard)
    stream = Consumer.shard_key(shard)
    group = @redis.xinfo(:groups, stream).find { |entry| entry['name'] == Consumer::GROUP }
    # The connector can have written to a stream before any consumer created the group.
    # Answering "nothing here" would mean nobody ever creates it, and those events would
    # sit on the stream for good.
    return @redis.xlen(stream).positive? if group.nil?
    return true if group['pending'].to_i.positive?

    # Asked as "is anything still there", not as "did the group reach the last id the
    # stream ever generated". MAXLEN trimming and XDEL take away entries the group was
    # never handed, and comparing the two ids would then report work that can never be
    # read again, for good, keeping this consumer on a dead stream and off the live ones.
    @redis.xrange(stream, "(#{group['last-delivered-id']}", '+', count: 1).any?
  rescue Redis::CommandError
    # No such key: a stream that was never written to has nothing to drain.
    false
  end
end
