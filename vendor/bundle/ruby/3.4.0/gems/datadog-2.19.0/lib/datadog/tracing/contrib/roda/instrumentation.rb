# frozen_string_literal: true

require_relative '../../metadata/ext'
require_relative 'ext'
require_relative '../analytics'

module Datadog
  module Tracing
    module Contrib
      module Roda
        # Instrumentation for Roda
        module Instrumentation
          def _roda_handle_main_route
            instrument(Ext::SPAN_REQUEST) { super }
          end

          def call
            instrument(Ext::SPAN_REQUEST) { super }
          end

          private

          def instrument(span_name, &block)
            Tracing.trace(span_name) do |span|
              begin
                request_method = request.request_method.to_s.upcase

                span.service = configuration[:service_name] if configuration[:service_name]

                span.type = Tracing::Metadata::Ext::HTTP::TYPE_INBOUND

                # Using the http method as a resource, since the URL/path can trigger
                # a possibly infinite number of resources.
                span.resource = request_method

                span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_URL, request.path)
                span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_METHOD, request_method)

                # Add analytics tag to the span
                if Contrib::Analytics.enabled?(configuration[:analytics_enabled])
                  Contrib::Analytics.set_sample_rate(span, configuration[:analytics_sample_rate])
                end

                # Measure service stats
                Contrib::Analytics.set_measured(span)
              ensure
                begin
                  response = yield
                rescue StandardError
                  # The status code is unknown to Roda and decided by the upstream web runner.
                  # In this case, spans default to status code 500 rather than a blank status code.
                  default_error_status = '500'
                  span.resource = "#{request_method} #{default_error_status}"
                  span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_STATUS_CODE, default_error_status)
                  raise
                end
              end

              status_code = response[0]

              # Adds status code to the resource name once the resource comes back
              span.resource = "#{request_method} #{status_code}"
              span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_STATUS_CODE, status_code)
              span.status = 1 if status_code.to_s.start_with?('5')
              response
            end
          end

          def configuration
            Datadog.configuration.tracing[:roda]
          end
        end
      end
    end
  end
end
