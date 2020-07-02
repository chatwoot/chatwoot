module Redis::Alfred
  CONVERSATION_MAILER_KEY = 'CONVERSATION::%d'.freeze

  # hash containing user_id key and status as value ONLINE_STATUS::%accountid
  ONLINE_STATUS = 'ONLINE_STATUS::%s'.freeze
  # sorted set storing online presense of account contacts : ONLINE_PRESENCE::%accountid::CONTACTS
  ONLINE_PRESENCE_CONTACTS = 'ONLINE_PRESENCE::%s::CONTACTS'.freeze
  # sorted set storing online presense of account users : ONLINE_PRESENCE::%accountid::USERS
  ONLINE_PRESENCE_USERS = 'ONLINE_PRESENCE::%s::USERS'.freeze

  class << self
    def rpoplpush(source, destination)
      $alfred.rpoplpush(source, destination)
    end

    def lpush(key, value)
      $alfred.lpush(key, value)
    end

    def delete(key)
      $alfred.del(key)
    end

    def lrem(key, value, count = 0)
      $alfred.lrem(key, count, value)
    end

    def setex(key, value, expiry = 1.day)
      $alfred.setex(key, expiry, value)
    end

    def set(key, value)
      $alfred.set(key, value)
    end

    def get(key)
      $alfred.get(key)
    end

    # hash operation

    # add a key value to redis hash
    def hset(key, field, value)
      $alfred.hset(key, field, value)
    end

    # get value from redis hash
    def hget(key, field)
      $alfred.hget(key, field)
    end

    # get values of multiple keys from redis hash
    def hmget(key, fields)
      $alfred.hmget(key, *fields)
    end

    # sorted set functions

    # add score and value for a key
    def zadd(key, score, value)
      $alfred.zadd(key, score, value)
    end

    # get score of a value for key
    def zscore(key, value)
      $alfred.zscore(key, value)
    end

    # get values by score
    def zrangebyscore(key, range_start, range_end)
      $alfred.zrangebyscore(key, range_start, range_end)
    end
  end
end
