# frozen_string_literal: true

module SidekiqAlive
  module Redis
    class Base
      def set(...)
        raise(NotImplementedError)
      end

      def zadd(set_key, ex, key)
        raise(NotImplementedError)
      end

      def zrange(set_key, start, stop)
        raise(NotImplementedError)
      end

      def zrangebyscore(set_key, min, max)
        raise(NotImplementedError)
      end

      def zrem(set_key, key)
        raise(NotImplementedError)
      end

      def delete(key)
        raise(NotImplementedError)
      end

      def ttl(...)
        redis { |r| r.ttl(...) }
      end
    end
  end
end
