# refer : https://redis.io/commands

module Redis::Alfred
  include Redis::RedisKeys

  class << self
    # key operations

    # set a value in redis
    def set(key, value, nx: false, ex: false) # rubocop:disable Naming/MethodParameterName
      $alfred.with { |conn| conn.set(key, value, nx: nx, ex: ex) }
    end

    # set a key with expiry period
    # TODO: Deprecate this method, use set with ex: 1.day instead
    def setex(key, value, expiry = 1.day)
      $alfred.with { |conn| conn.setex(key, expiry, value) }
    end

    def get(key)
      $alfred.with { |conn| conn.get(key) }
    end

    def delete(key)
      $alfred.with { |conn| conn.del(key) }
    end

    # increment a key by 1. throws error if key value is incompatible
    # sets key to 0 before operation if key doesn't exist
    def incr(key)
      $alfred.with { |conn| conn.incr(key) }
    end

    def exists?(key)
      $alfred.with { |conn| conn.exists?(key) }
    end

    # set expiry on a key in seconds
    def expire(key, seconds)
      $alfred.with { |conn| conn.expire(key, seconds) }
    end

    # scan keys matching a pattern
    def scan_each(match: nil, count: 100, &)
      $alfred.with do |conn|
        conn.scan_each(match: match, count: count, &)
      end
    end

    # count keys matching a pattern
    def keys_count(pattern)
      count = 0
      scan_each(match: pattern) { count += 1 }
      count
    end

    # list operations

    def llen(key)
      $alfred.with { |conn| conn.llen(key) }
    end

    def lrange(key, start_index = 0, end_index = -1)
      $alfred.with { |conn| conn.lrange(key, start_index, end_index) }
    end

    def rpop(key)
      $alfred.with { |conn| conn.rpop(key) }
    end

    def lpush(key, values)
      $alfred.with { |conn| conn.lpush(key, values) }
    end

    def rpoplpush(source, destination)
      $alfred.with { |conn| conn.rpoplpush(source, destination) }
    end

    def lrem(key, value, count = 0)
      $alfred.with { |conn| conn.lrem(key, count, value) }
    end

    # hash operations

    # add a key value to redis hash
    def hset(key, field, value)
      $alfred.with { |conn| conn.hset(key, field, value) }
    end

    # get value from redis hash
    def hget(key, field)
      $alfred.with { |conn| conn.hget(key, field) }
    end

    # get values of multiple keys from redis hash
    def hmget(key, fields)
      $alfred.with { |conn| conn.hmget(key, *fields) }
    end

    # sorted set operations

    # add score and value for a key
    # Modern Redis syntax: zadd(key, [[score, member], ...])
    def zadd(key, score, value = nil)
      if value.nil? && score.is_a?(Array)
        # New syntax: score is actually an array of [score, member] pairs
        $alfred.with { |conn| conn.zadd(key, score) }
      else
        # Support old syntax for backward compatibility
        $alfred.with { |conn| conn.zadd(key, [[score, value]]) }
      end
    end

    # get score of a value for key
    def zscore(key, value)
      $alfred.with { |conn| conn.zscore(key, value) }
    end

    # count members in a sorted set with scores within the given range
    def zcount(key, min_score, max_score)
      $alfred.with { |conn| conn.zcount(key, min_score, max_score) }
    end

    # get the number of members in a sorted set
    def zcard(key)
      $alfred.with { |conn| conn.zcard(key) }
    end

    # get values by score
    def zrangebyscore(key, range_start, range_end, with_scores: false, limit: nil)
      options = {}
      options[:with_scores] = with_scores if with_scores
      options[:limit] = limit if limit
      $alfred.with { |conn| conn.zrangebyscore(key, range_start, range_end, **options) }
    end

    # remove values by score
    # exclusive score is specified by prefixing (
    def zremrangebyscore(key, range_start, range_end)
      $alfred.with { |conn| conn.zremrangebyscore(key, range_start, range_end) }
    end
  end
end
