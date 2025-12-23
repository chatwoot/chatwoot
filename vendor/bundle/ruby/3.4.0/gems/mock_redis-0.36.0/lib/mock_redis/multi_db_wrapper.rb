require 'mock_redis/undef_redis_methods'

class MockRedis
  class MultiDbWrapper
    include UndefRedisMethods

    def initialize(db)
      @db_index = 0

      @prototype_db = db.clone

      @databases = Hash.new { |h, k| h[k] = @prototype_db.clone }
      @databases[@db_index] = db
    end

    def respond_to?(method, include_private = false)
      super || current_db.respond_to?(method, include_private)
    end

    ruby2_keywords def method_missing(method, *args, &block)
      current_db.send(method, *args, &block)
    end

    def initialize_copy(source)
      super
      @databases = @databases.clone
      @databases.each_key do |k|
        @databases[k] = @databases[k].clone
      end
    end

    # Redis commands
    def flushall
      @databases.values.each(&:flushdb)
      'OK'
    end

    def move(key, db_index)
      src = current_db
      dest = db(db_index)

      if !src.exists?(key) || dest.exists?(key)
        false
      else
        case current_db.type(key)
        when 'hash'
          dest.hmset(key, *src.hgetall(key).map { |k, v| [k, v] }.flatten)
        when 'list'
          while value = src.rpop(key)
            dest.lpush(key, value)
          end
        when 'set'
          while value = src.spop(key)
            dest.sadd(key, value)
          end
        when 'string'
          dest.set(key, src.get(key))
        when 'zset'
          src.zrange(key, 0, -1, :with_scores => true).each do |(m, s)|
            dest.zadd(key, s, m)
          end
        else
          raise ArgumentError,
          "Can't move a key of type #{current_db.type(key).inspect}"
        end

        src.del(key)
        true
      end
    end

    def select(db_index)
      @db_index = db_index.to_i
      'OK'
    end

    private

    def current_db
      @databases[@db_index]
    end

    def db(index)
      @databases[index]
    end
  end
end
