# frozen_string_literal: true

require_relative '../patcher'
require_relative 'ext'
require_relative 'configuration/resolver'

module Datadog
  module Tracing
    module Contrib
      module Redis
        # Patcher enables patching of 'redis' module.
        module Patcher
          include Contrib::Patcher

          # Patch for redis instance (with redis < 5)
          module DatadogPinPatch
            def self.included(base)
              base.prepend(InstanceMethods)
            end

            # Instance method patch for redis instance
            module InstanceMethods
              def datadog_pin=(pin)
                pin.onto(datadog_target)
              end

              def datadog_target
                # For `redis-rb` 4.x
                return _client if respond_to?(:_client)
                # For `redis-rb` 3.x
                return client if respond_to?(:client)

                Datadog.logger.warn 'Fail to apply configuration on redis client instance with '  \
                                                        '`Datadog.configure_onto(redis)`.'

                # Null object instead of raising error
                self
              end
            end
          end

          # Patch for redis instance (with redis >= 5)
          module NotSupportedNoticePatch
            def self.included(base)
              base.prepend(InstanceMethods)
            end

            # Instance method patch for redis instance
            module InstanceMethods
              def datadog_pin=(_pin)
                Datadog.logger.warn \
                  '`Datadog.configure_onto(redis)` is not supported on Redis 5+. To instrument '\
                  "a redis instance with custom configuration, please initialize it with:\n"\
                  "  `Redis.new(..., custom: { datadog: { service_name: 'my-service' } })`.\n\n" \
                  'See: https://github.com/DataDog/dd-trace-rb/blob/master/docs/GettingStarted.md#redis'
              end
            end
          end

          module_function

          def default_tags
            [].tap do |tags|
              tags << "target_redis_version:#{Integration.redis_version}"               if Integration.redis_version
              tags << "target_redis_client_version:#{Integration.redis_client_version}" if Integration.redis_client_version
            end
          end

          def patch
            # Redis 5+ extracts RedisClient to its own gem and provide instrumentation interface
            if Integration.redis_client_compatible?
              require_relative 'trace_middleware'

              ::RedisClient.register(TraceMiddleware)
            end

            if Integration.redis_compatible?
              if Integration.redis_version < Gem::Version.new('5.0.0')
                require_relative 'instrumentation'

                ::Redis.include(DatadogPinPatch)
                ::Redis::Client.include(Instrumentation)
              else # warn about non-supported configure_onto usage
                ::Redis.include(NotSupportedNoticePatch)
              end
            end
          end
        end
      end
    end
  end
end
