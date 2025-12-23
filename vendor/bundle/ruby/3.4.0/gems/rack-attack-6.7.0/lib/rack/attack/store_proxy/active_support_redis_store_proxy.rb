# frozen_string_literal: true

require 'rack/attack/base_proxy'

module Rack
  class Attack
    module StoreProxy
      class ActiveSupportRedisStoreProxy < BaseProxy
        def self.handle?(store)
          defined?(::Redis) &&
            defined?(::ActiveSupport::Cache::RedisStore) &&
            store.is_a?(::ActiveSupport::Cache::RedisStore)
        end

        def increment(name, amount = 1, options = {})
          # #increment ignores options[:expires_in].
          #
          # So in order to workaround this we use #write (which sets expiration) to initialize
          # the counter. After that we continue using the original #increment.
          if options[:expires_in] && !read(name)
            write(name, amount, options)

            amount
          else
            super
          end
        end

        def read(name, options = {})
          super(name, options.merge!(raw: true))
        end

        def write(name, value, options = {})
          super(name, value, options.merge!(raw: true))
        end
      end
    end
  end
end
