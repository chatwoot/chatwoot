# frozen_string_literal: true

require_relative '../../metadata/ext'
require_relative '../http'
require_relative 'ext'

module Datadog
  module Tracing
    module Contrib
      module Ethon
        # Ethon MultiPatch
        module MultiPatch
          def self.included(base)
            # No need to prepend here since add method is included into Multi class
            base.include(InstanceMethods)
          end

          # InstanceMethods - implementing instrumentation
          module InstanceMethods
            def add(easy)
              handles = super
              return handles unless handles && Tracing.enabled?

              if datadog_multi_performing?
                # Start Easy span in case Multi is already performing
                easy.datadog_before_request(continue_from: datadog_multi_trace_digest)
              end
              handles
            end

            def perform
              if Tracing.enabled?
                easy_handles.each do |easy|
                  easy.datadog_before_request(continue_from: datadog_multi_trace_digest) unless easy.datadog_span_started?
                end
              end
              super
            ensure
              if Tracing.enabled? && datadog_multi_performing?
                @datadog_multi_span.finish
                @datadog_multi_span = nil
                @datadog_multi_trace_digest = nil
              end
            end

            private

            def datadog_multi_performing?
              instance_variable_defined?(:@datadog_multi_span) && !@datadog_multi_span.nil?
            end

            def datadog_multi_trace_digest
              return unless datadog_multi_span

              @datadog_multi_trace_digest
            end

            def datadog_multi_span
              return @datadog_multi_span if datadog_multi_performing?

              @datadog_multi_span = Tracing.trace(
                Ext::SPAN_MULTI_REQUEST,
                service: datadog_configuration[:service_name]
              )
              @datadog_multi_trace_digest = Tracing.active_trace.to_digest

              @datadog_multi_span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
              @datadog_multi_span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_MULTI_REQUEST)

              @datadog_multi_span.set_tag(Tracing::Metadata::Ext::TAG_KIND, Tracing::Metadata::Ext::SpanKind::TAG_CLIENT)

              # Tag original global service name if not used
              if @datadog_multi_span.service != Datadog.configuration.service
                @datadog_multi_span.set_tag(
                  Tracing::Contrib::Ext::Metadata::TAG_BASE_SERVICE,
                  Datadog.configuration.service
                )
              end

              # Set analytics sample rate
              Contrib::Analytics.set_sample_rate(@datadog_multi_span, analytics_sample_rate) if analytics_enabled?

              @datadog_multi_span
            end

            def datadog_configuration
              Datadog.configuration.tracing[:ethon]
            end

            def analytics_enabled?
              Contrib::Analytics.enabled?(datadog_configuration[:analytics_enabled])
            end

            def analytics_sample_rate
              datadog_configuration[:analytics_sample_rate]
            end
          end
        end
      end
    end
  end
end
