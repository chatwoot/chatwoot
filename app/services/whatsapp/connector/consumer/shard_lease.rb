# The lock that makes a shard single-reader. One consumer holds a shard's lease, reads
# it, and keeps the lease alive for as long as its worker is around; a process that dies
# stops renewing and the lease lapses, which is how its shards move to the survivors.
#
# Taking is a plain SET NX, but extending and giving back both compare the holder and act
# in the same round trip. Read-then-write would let the lease change hands in between,
# and this process would then extend a lease another consumer is already reading under,
# or delete one a third has since taken.
class Whatsapp::Connector::Consumer::ShardLease
  Consumer = Whatsapp::Connector::Consumer

  # Long enough to survive a slow tick, short enough that a crashed process's shards
  # move within seconds.
  TTL = 30
  # How much of the TTL a holder refuses to spend. A dispatch decided on a lease with
  # seconds left can outlive it, and by then the shard may already be a peer's, so the
  # margin is what keeps the decision from being made that late.
  FRESH_MARGIN = 5

  RENEW = <<~LUA.freeze
    if redis.call('get', KEYS[1]) == ARGV[1] then
      return redis.call('expire', KEYS[1], ARGV[2])
    end
    return 0
  LUA

  RELEASE = <<~LUA.freeze
    if redis.call('get', KEYS[1]) == ARGV[1] then
      return redis.call('del', KEYS[1])
    end
    return 0
  LUA

  def initialize(redis, consumer_id)
    @redis = redis
    @consumer_id = consumer_id
    # Written by the supervisor thread, read by every worker thread.
    @held_since = Concurrent::Map.new
  end

  def take(shard)
    taken = @redis.set(key(shard), @consumer_id, nx: true, ex: TTL).present?
    mark(shard) if taken
    taken
  end

  # False when the lease is no longer ours, which is the caller's signal to stop reading
  # the shard: somebody else may already have it.
  def renew(shard)
    renewed = @redis.eval(RENEW, keys: [key(shard)], argv: [@consumer_id, TTL]) == 1
    renewed ? mark(shard) : @held_since.delete(shard)
    renewed
  end

  def release(shard)
    @held_since.delete(shard)
    @redis.eval(RELEASE, keys: [key(shard)], argv: [@consumer_id])
  end

  # Whether this consumer can still be sure the shard is its own, answered from its own
  # clock and without asking Redis, because it is asked before every single dispatch.
  #
  # It is the renewal that has to have been recent, not the key that has to exist: a
  # renewal that cannot reach Redis leaves the key to lapse on the server, and a holder
  # that kept reading in the meantime would be reading a shard a peer has taken.
  def fresh?(shard)
    held = @held_since[shard]
    return false if held.nil?

    monotonic - held < TTL - FRESH_MARGIN
  end

  private

  def mark(shard)
    @held_since[shard] = monotonic
  end

  # Monotonic on purpose: a clock that steps backwards would make a lapsed lease look
  # fresh again.
  def monotonic
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  def key(shard)
    Consumer.lease_key(shard)
  end
end
