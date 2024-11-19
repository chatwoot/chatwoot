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
    def zadd(key, score, value)
      $alfred.with { |conn| conn.zadd(key, score, value) }
    end

    # get score of a value for key
    def zscore(key, value)
      $alfred.with { |conn| conn.zscore(key, value) }
    end

    # get values by score
    def zrangebyscore(key, range_start, range_end)
      $alfred.with { |conn| conn.zrangebyscore(key, range_start, range_end) }
    end

    # remove values by score
    # exclusive score is specified by prefixing (
    def zremrangebyscore(key, range_start, range_end)
      $alfred.with { |conn| conn.zremrangebyscore(key, range_start, range_end) }
    end
  end
end
