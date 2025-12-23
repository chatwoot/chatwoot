# frozen_string_literal: true

require_relative "base"

module SidekiqAlive
  module Redis
    # Wrapper for `redis-client` gem used by `sidekiq` > 7
    # https://github.com/redis-rb/redis-client
    class RedisClientGem < Base
      def initialize(capsule = nil)
        super()

        @capsule = Sidekiq.default_configuration.capsules[capsule || CAPSULE_NAME]
      end

      def set(key, time:, ex:)
        redis { |r| r.call("SET", key, time, ex: ex) }
      end

      def get(key)
        redis { |r| r.call("GET", key) }
      end

      def zadd(set_key, ex, key)
        redis { |r| r.call("ZADD", set_key, ex, key) }
      end

      def zrange(set_key, start, stop)
        redis { |r| r.call("ZRANGE", set_key, start, stop) }
      end

      def zrangebyscore(set_key, min, max)
        redis { |r| r.call("ZRANGEBYSCORE", set_key, min, max) }
      end

      def zrem(set_key, key)
        redis { |r| r.call("ZREM", set_key, key) }
      end

      def delete(key)
        redis { |r| r.call("DEL", key) }
      end

      private

      def redis(&block)
        # Default to Sidekiq.redis if capsule is not configured yet but redis adapter is accessed
        (@capsule || Sidekiq).redis(&block)
      end
    end
  end
end
