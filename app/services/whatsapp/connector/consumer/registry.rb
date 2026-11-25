# Who is reading the event streams right now.
#
# Every consumer publishes a short-lived key naming the shards it holds, and reads the
# others' to work out its own share. There is no coordinator: they all compute the same
# numbers from the same registry, so a process joining or leaving redistributes the
# shards without anyone being told.
class Whatsapp::Connector::Consumer::Registry
  Consumer = Whatsapp::Connector::Consumer

  # Short enough that a process which stopped announcing itself is out of the count in
  # seconds, long enough to survive one slow tick.
  TTL = 15

  def initialize(redis, consumer_id)
    @redis = redis
    @consumer_id = consumer_id
  end

  # The heartbeat key is what says the consumer is alive, and its TTL is the only clock:
  # the index next to it just names the keys to look at. The key keeps the name and shape
  # it always had, because the previous version finds its peers by that name, and a
  # rolling deploy has both versions running at once.
  def announce(shards)
    @redis.multi do |transaction|
      transaction.set(key(@consumer_id), { 'shards' => shards.sort, 'at' => Time.current.to_i }.to_json, ex: TTL)
      transaction.sadd(index, @consumer_id)
    end
  end

  # A process on its way out takes itself off at once rather than waiting for its key to
  # lapse: it is not going to read anything again, and a replacement that counted it
  # would claim a fraction of the shards and leave the rest unread for the grace period.
  # The index entry goes with the next reader, as for any other heartbeat that is gone.
  def withdraw
    @redis.del(key(@consumer_id))
  end

  # How many shards each live consumer says it holds, this one included.
  #
  # Read through the index, never by looking for the keys: this runs every tick in every
  # consumer, against the Redis the whole installation shares, and a SCAN for a pattern
  # walks every key in it however few match. That walk cost a production Redis 72% of its
  # CPU, with 94 thousand keys and six heartbeats among them.
  def held_counts
    ids = @redis.smembers(index)
    return [] if ids.empty?

    heartbeats = ids.zip(@redis.mget(*ids.map { |id| key(id) }))
    lapsed, live = heartbeats.partition { |_id, heartbeat| heartbeat.nil? }
    # A process killed without a shutdown never withdraws, so whoever finds its heartbeat
    # gone takes it out of the index.
    @redis.srem(index, lapsed.map(&:first)) if lapsed.any?
    live.map { |_id, heartbeat| Array(parse(heartbeat)['shards']).size }
  end

  private

  # A heartbeat this build cannot read is still a consumer that is alive and holding
  # something, so it counts as a peer with nothing rather than not counting at all.
  def parse(heartbeat)
    JSON.parse(heartbeat)
  rescue JSON::ParserError
    {}
  end

  # Named so the previous version's search for heartbeats, `consumer:*`, does not find it.
  def index
    Whatsapp::Connector.key('consumers')
  end

  def key(consumer_id)
    Consumer.consumer_key(consumer_id)
  end
end
