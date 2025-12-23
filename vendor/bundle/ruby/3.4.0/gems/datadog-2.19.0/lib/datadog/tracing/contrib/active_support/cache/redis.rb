# frozen_string_literal: true

require_relative '../../support'
require_relative 'patcher'

module Datadog
  module Tracing
    module Contrib
      module ActiveSupport
        module Cache
          # Support for Redis with ActiveSupport
          module Redis
            # Patching behavior for Redis with ActiveSupport
            module Patcher
              # For Rails < 5.2 w/ redis-activesupport...
              # When Redis is used, we can't only patch Cache::Store as it is
              # Cache::RedisStore, a sub-class of it that is used, in practice.
              # We need to do a per-method monkey patching as some of them might
              # be redefined, and some of them not. The latest version of redis-activesupport
              # redefines write but leaves untouched read and delete:
              # https://github.com/redis-store/redis-activesupport/blob/v4.1.5/lib/active_support/cache/redis_store.rb
              #
              # For Rails >= 5.2 w/o redis-activesupport...
              # ActiveSupport includes a Redis cache store internally, and does not require these overrides.
              # https://github.com/rails/rails/blob/master/activesupport/lib/active_support/cache/redis_cache_store.rb
              def patch_redis_store?(meth)
                !Gem.loaded_specs['redis-activesupport'].nil? \
                  && defined?(::ActiveSupport::Cache::RedisStore) \
                  && ::ActiveSupport::Cache::RedisStore.instance_methods(false).include?(meth)
              end

              # Patches the Rails built-in Redis cache backend `redis_cache_store`, added in Rails 5.2.
              # We avoid loading the RedisCacheStore class, as it invokes the statement `gem "redis", ">= 4.0.1"` which
              # fails if the application is using an old version of Redis, or not using Redis at all.
              # @see https://github.com/rails/rails/blob/d0dcb8fa6073a0c4d42600c15e82e3bb386b27d3/activesupport/lib/active_support/cache/redis_cache_store.rb#L4
              def patch_redis_cache_store?(meth)
                Gem.loaded_specs['redis'] &&
                  Support.fully_loaded?(::ActiveSupport::Cache, :RedisCacheStore) &&
                  ::ActiveSupport::Cache::RedisCacheStore.instance_methods(false).include?(meth)
              end

              def cache_store_class(meth)
                if patch_redis_store?(meth)
                  [::ActiveSupport::Cache::RedisStore, ::ActiveSupport::Cache::Store]
                elsif patch_redis_cache_store?(meth)
                  [::ActiveSupport::Cache::RedisCacheStore, ::ActiveSupport::Cache::Store]
                else
                  super
                end
              end
            end

            # Decorate Cache patcher with Redis support
            Cache::Patcher.singleton_class.prepend(Redis::Patcher)
          end
        end
      end
    end
  end
end
