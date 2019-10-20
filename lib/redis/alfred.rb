module Redis::Alfred
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
  end
end
