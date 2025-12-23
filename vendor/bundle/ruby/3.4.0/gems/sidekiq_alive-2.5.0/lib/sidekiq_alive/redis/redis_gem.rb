# frozen_string_literal: true

require_relative "base"

module SidekiqAlive
  module Redis
    # Wrapper for `redis` gem used by sidekiq < 7
    # https://github.com/redis/redis-rb
    class RedisGem < Base
      def set(key, time:, ex:)
        redis { |r| r.set(key, time, ex: ex) }
      end

      def get(key)
        redis { |r| r.get(key) }
      end

      def zadd(set_key, ex, key)
        redis { |r| r.zadd(set_key, ex, key) }
      end

      def zrange(set_key, start, stop)
        redis { |r| r.zrange(set_key, start, stop) }
      end

      def zrangebyscore(set_key, min, max)
        redis { |r| r.zrangebyscore(set_key, min, max) }
      end

      def zrem(set_key, key)
        redis { |r| r.zrem(set_key, key) }
      end

      def delete(key)
        redis { |r| r.del(key) }
      end

      private

      def redis(&block)
        Sidekiq.redis(&block)
      end
    end
  end
end
