# frozen_string_literal: true

require_relative 'gateway/middleware'

module Datadog
  module AppSec
    # Instrumentation for AppSec
    module Instrumentation
      # Instrumentation gateway implementation
      class Gateway
        def initialize
          @middlewares = Hash.new { |h, k| h[k] = [] }
          @pushed_events = {}
        end

        # NOTE: Be careful with pushed names because every pushed event name
        #       is recorded in order to provide an ability to any subscriber
        #       to check wether an arbitrary event had happened.
        #
        # WARNING: If we start pushing generated names we should consider
        #          limiting the storage of pushed names.
        def push(name, env, &block)
          @pushed_events[name] = true

          block ||= -> {}
          middlewares_for_name = @middlewares[name]

          return [block.call, nil] if middlewares_for_name.empty?

          wrapped = lambda do |_env|
            [block.call, nil]
          end

          # TODO: handle exceptions, except for wrapped
          stack = middlewares_for_name.reverse.reduce(wrapped) do |next_, middleware|
            lambda do |env_|
              middleware.call(next_, env_)
            end
          end

          stack.call(env)
        end

        def watch(name, key, &block)
          @middlewares[name] << Middleware.new(key, &block) unless @middlewares[name].any? { |m| m.key == key }
        end

        def pushed?(name)
          @pushed_events.key?(name)
        end
      end

      # NOTE: This left as-is and will be depricated soon.
      def self.gateway
        @gateway ||= Gateway.new # TODO: not thread safe
      end
    end
  end
end
