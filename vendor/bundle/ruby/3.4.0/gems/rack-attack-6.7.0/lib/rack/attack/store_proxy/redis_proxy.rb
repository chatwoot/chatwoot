# frozen_string_literal: true

require 'rack/attack/base_proxy'

module Rack
  class Attack
    module StoreProxy
      class RedisProxy < BaseProxy
        def initialize(*args)
          if Gem::Version.new(Redis::VERSION) < Gem::Version.new("3")
            warn 'RackAttack requires Redis gem >= 3.0.0.'
          end

          super(*args)
        end

        def self.handle?(store)
          defined?(::Redis) && store.class == ::Redis
        end

        def read(key)
          rescuing { get(key) }
        end

        def write(key, value, options = {})
          if (expires_in = options[:expires_in])
            rescuing { setex(key, expires_in, value) }
          else
            rescuing { set(key, value) }
          end
        end

        def increment(key, amount, options = {})
          rescuing do
            pipelined do |redis|
              redis.incrby(key, amount)
              redis.expire(key, options[:expires_in]) if options[:expires_in]
            end.first
          end
        end

        def delete(key, _options = {})
          rescuing { del(key) }
        end

        def delete_matched(matcher, _options = nil)
          cursor = "0"

          rescuing do
            # Fetch keys in batches using SCAN to avoid blocking the Redis server.
            loop do
              cursor, keys = scan(cursor, match: matcher, count: 1000)
              del(*keys) unless keys.empty?
              break if cursor == "0"
            end
          end
        end

        private

        def rescuing
          yield
        rescue Redis::BaseConnectionError
          nil
        end
      end
    end
  end
end
