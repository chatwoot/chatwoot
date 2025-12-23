# frozen_string_literal: true

require 'datadog/tracing/utils'

module Datadog
  module OpenTelemetry
    module Trace
      # Stores associated Datadog entities to the OpenTelemetry Span.
      module Span
        # Attributes are equivalent to span tags and metrics.
        def set_attribute(key, value)
          res = super
          # Attributes can get dropped or their values truncated by `super`
          datadog_set_attribute(key)
          res
        end

        # Record an exception during the execution of this span. Multiple exceptions
        # can be recorded on a span.
        #
        # @param [Exception] exception The exception to recorded
        # @param [optional Hash{String => String, Numeric, Boolean, Array<String, Numeric, Boolean>}]
        #   attributes One or more key:value pairs, where the keys must be
        #   strings and the values may be (array of) string, boolean or numeric
        #   type.
        #
        # @return [void]
        def record_exception(exception, attributes: nil)
          res = super
          if (span = datadog_span)
            # Sets the exception attributes as span error tags. The values in the attribute hash MUST
            # take precedence over the type, message and stacktrace inferred from the exception object
            type = attributes&.[]('exception.type') || exception.class.to_s
            message = attributes&.[]('exception.message') || exception.message
            stacktrace = attributes&.[]('exception.stacktrace') || exception.full_message(highlight: false, order: :top)
            span.set_error_tags([type, message, stacktrace])
          end
          res
        end

        # `alias` performed to match {OpenTelemetry::SDK::Trace::Span} aliasing upstream
        alias []= set_attribute

        # Attributes are equivalent to span tags and metrics.
        def add_attributes(attributes)
          res = super
          # Attributes can get dropped or their values truncated by `super`
          attributes.each_key { |key| datadog_set_attribute(key) }
          res
        end

        # Captures changes to span error state.
        def status=(s)
          super

          return unless status # Return if status are currently disabled by OpenTelemetry.
          return unless (span = datadog_span)

          # Status code can only change into an error state.
          # Other change operations should be ignored.
          span.set_error(status.description) if status && status.code == ::OpenTelemetry::Trace::Status::ERROR
        end

        # Create a meaningful Datadog operation name from the OpenTelemetry
        # semantic convention for span kind and span attributes.
        # @see https://opentelemetry.io/docs/specs/semconv/general/trace/

        # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
        def self.enrich_name(kind, attrs)
          if attrs.key?('http.request.method')
            return 'http.server.request' if kind == :server
            return 'http.client.request' if kind == :client
          end

          return "#{attrs['db.system']}.query" if attrs.key?('db.system') && kind == :client

          if (attrs.key?('messaging.system') || attrs.key?('messaging.operation')) &&
              [:consumer, :producer, :server, :client].include?(kind)

            return "#{attrs['messaging.system']}.#{attrs['messaging.operation']}"
          end

          if attrs.key?('rpc.system')
            if attrs['rpc.system'] == 'aws-api' && kind == :client
              service = attrs['rpc.service']
              return "aws.#{service || 'client'}.request"
            end

            if kind == :client
              return "#{attrs['rpc.system']}.client.request"
            elsif kind == :server
              return "#{attrs['rpc.system']}.server.request"
            end
          end

          if attrs.key?('faas.invoked_provider') && attrs.key?('faas.invoked_name') && kind == :client
            provider = attrs['faas.invoked_provider']
            name = attrs['faas.invoked_name']
            return "#{provider}.#{name}.invoke"
          end

          return "#{attrs['faas.trigger']}.invoke" if attrs.key?('faas.trigger') && kind == :server

          return 'graphql.server.request' if attrs.key?('graphql.operation.type')

          if kind == :server
            protocol = attrs['network.protocol.name']
            return protocol ? "#{protocol}.server.request" : 'server.request'
          end

          if kind == :client
            protocol = attrs['network.protocol.name']
            return protocol ? "#{protocol}.client.request" : 'client.request'
          end

          kind.to_s
        end
        # rubocop:enable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity

        private

        def datadog_set_attribute(key)
          # Return if attributes are currently disabled by OpenTelemetry.
          return unless defined?(@attributes) && @attributes
          return unless (span = datadog_span)

          # DEV: Accesses `@attributes` directly, since using `#attributes`
          # DEV: clones the hash, causing unnecessary overhead.
          if @attributes.key?(key)
            # Try to find a richer operation name, unless an explicit override was provided.
            if !@attributes.key?('operation.name') && (rich_name = Span.enrich_name(kind, @attributes))
              span.name = rich_name.downcase
            end

            Tracing::Utils.serialize_attribute(key, @attributes[key]).each do |new_key, value|
              override_datadog_values(span, new_key, value)

              # When an attribute is used to override a Datadog Span property,
              # it should NOT be set as a Datadog Span tag.
              span.set_tag(new_key, value) unless DATADOG_SPAN_ATTRIBUTE_OVERRIDES.include?(new_key)
            end
          else
            span.clear_tag(key)

            if key == 'service.name'
              # By removing the service name, we set it to the fallback default,
              # effectively removing the `service` attribute from OpenTelemetry's perspective.
              span.service = Datadog.send(:components).tracer.default_service
            end
          end
        end

        # Some special attributes can override Datadog Span fields beyond tags and metrics.
        # @return [Boolean] true if the key is a Datadog Span override attribute, false otherwise
        def override_datadog_values(span, key, value)
          span.name = value if key == 'operation.name'
          span.resource = value if key == 'resource.name'
          span.service = value if key == 'service.name'
          span.type = value if key == 'span.type'

          if key == 'analytics.event' && value.respond_to?(:casecmp)
            Datadog::Tracing::Analytics.set_sample_rate(
              span,
              value.casecmp('true') == 0 ? 1 : 0
            )
          end

          span.set_tag('http.status_code', value) if key == 'http.response.status_code'
        end

        DATADOG_SPAN_ATTRIBUTE_OVERRIDES = ['analytics.event', 'operation.name', 'resource.name', 'service.name',
                                            'span.type', 'http.response.status_code'].freeze

        ::OpenTelemetry::SDK::Trace::Span.prepend(self)
      end
    end
  end
end
