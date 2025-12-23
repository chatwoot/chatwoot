# frozen_string_literal: true

require 'sucker_punch'

require_relative '../../metadata/ext'
require_relative '../analytics'
require_relative 'ext'

module Datadog
  module Tracing
    module Contrib
      module SuckerPunch
        # Defines instrumentation patches for the `sucker_punch` gem
        module Instrumentation
          module_function

          # rubocop:disable Metrics/MethodLength
          # rubocop:disable Metrics/AbcSize
          def patch!
            # rubocop:disable Metrics/BlockLength
            ::SuckerPunch::Job::ClassMethods.class_eval do
              alias_method :__run_perform_without_datadog, :__run_perform
              def __run_perform(*args)
                Datadog::Tracing.send(:tracer).provider.context = Datadog::Tracing::Context.new

                __with_instrumentation(Ext::SPAN_PERFORM) do |span|
                  span.resource = "PROCESS #{self}"

                  span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_PERFORM)

                  # Set analytics sample rate
                  if Datadog::Tracing::Contrib::Analytics.enabled?(datadog_configuration[:analytics_enabled])
                    Datadog::Tracing::Contrib::Analytics.set_sample_rate(
                      span,
                      datadog_configuration[:analytics_sample_rate]
                    )
                  end

                  # Measure service stats
                  Datadog::Tracing::Contrib::Analytics.set_measured(span)

                  __run_perform_without_datadog(*args)
                end
              rescue => e
                ::SuckerPunch.__exception_handler.call(e, self, args)
              end
              ruby2_keywords :__run_perform if respond_to?(:ruby2_keywords, true)

              alias_method :__perform_async, :perform_async
              def perform_async(*args)
                __with_instrumentation(Ext::SPAN_PERFORM_ASYNC) do |span|
                  span.resource = "ENQUEUE #{self}"

                  span.set_tag(Datadog::Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_PERFORM_ASYNC)

                  # Measure service stats
                  Datadog::Tracing::Contrib::Analytics.set_measured(span)

                  __perform_async(*args)
                end
              end
              ruby2_keywords :perform_async if respond_to?(:ruby2_keywords, true)

              alias_method :__perform_in, :perform_in
              def perform_in(interval, *args)
                __with_instrumentation(Ext::SPAN_PERFORM_IN) do |span|
                  span.resource = "ENQUEUE #{self}"

                  span.set_tag(Datadog::Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_PERFORM_IN)

                  span.set_tag(Ext::TAG_PERFORM_IN, interval)

                  # Measure service stats
                  Datadog::Tracing::Contrib::Analytics.set_measured(span)

                  __perform_in(interval, *args)
                end
              end
              ruby2_keywords :perform_in if respond_to?(:ruby2_keywords, true)

              private

              def datadog_configuration
                Datadog.configuration.tracing[:sucker_punch]
              end

              def __with_instrumentation(name)
                Datadog::Tracing.trace(name, service: datadog_configuration[:service_name]) do |span|
                  span.type = Datadog::Tracing::Metadata::Ext::AppTypes::TYPE_WORKER
                  span.set_tag(Datadog::Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
                  span.set_tag(Ext::TAG_QUEUE, to_s)
                  yield span
                end
              end
            end
            # rubocop:enable Metrics/BlockLength
          end
          # rubocop:enable Metrics/MethodLength
          # rubocop:enable Metrics/AbcSize
        end
      end
    end
  end
end
