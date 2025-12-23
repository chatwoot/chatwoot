require 'mock_redis/undef_redis_methods'

class MockRedis
  class ExpireWrapper
    include UndefRedisMethods

    def respond_to?(method, include_private = false)
      super || @db.respond_to?(method)
    end

    def initialize(db)
      @db = db
    end

    ruby2_keywords def method_missing(method, *args, &block)
      @db.expire_keys
      @db.send(method, *args, &block)
    end

    def initialize_copy(source)
      super
      @db = @db.clone
    end
  end
end
