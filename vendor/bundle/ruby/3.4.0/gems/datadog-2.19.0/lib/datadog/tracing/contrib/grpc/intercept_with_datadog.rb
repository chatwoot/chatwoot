# frozen_string_literal: true

require_relative 'datadog_interceptor'

module Datadog
  module Tracing
    module Contrib
      module GRPC
        # :nodoc:
        # The `#intercept!` method is implemented in gRPC; this module
        # will be prepended to the original class, effectively injecting
        # our tracing middleware into the head of the call chain.
        module InterceptWithDatadog
          def intercept!(type, args = {})
            if should_prepend?
              datadog_interceptor = choose_datadog_interceptor(args)

              @interceptors.unshift(datadog_interceptor.new) if datadog_interceptor

              @trace_started = true
            end

            super
          end

          private

          def should_prepend?
            !trace_started? && !already_prepended?
          end

          def trace_started?
            defined?(@trace_started) && @trace_started
          end

          def already_prepended?
            @interceptors.any? do |interceptor|
              interceptor.class.ancestors.include?(Datadog::Tracing::Contrib::GRPC::DatadogInterceptor::Base)
            end
          end

          def choose_datadog_interceptor(args)
            if args.key?(:metadata)
              Datadog::Tracing::Contrib::GRPC::DatadogInterceptor::Client
            elsif args.key?(:call)
              Datadog::Tracing::Contrib::GRPC::DatadogInterceptor::Server
            end
          end
        end
      end
    end
  end
end
