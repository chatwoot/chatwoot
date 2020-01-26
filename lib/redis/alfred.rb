module Redis::Alfred
  CONVERSATION_MAILER_KEY = 'CONVERSATION::%d'.freeze

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

    def get(key)
      $alfred.get(key)
    end
  end
end
