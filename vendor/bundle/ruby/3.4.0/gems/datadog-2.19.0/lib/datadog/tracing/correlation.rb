# frozen_string_literal: true

require_relative 'utils'
require_relative '../core/logging/ext'

module Datadog
  module Tracing
    # Contains behavior for managing correlations with tracing
    # e.g. Retrieve a correlation to the current trace for logging, etc.
    # This class is for usage with log correlation.
    # To continue from a trace, users should use TraceDigest instead.
    module Correlation
      # Represents current trace state with key identifiers
      # @public_api
      class Identifier
        LOG_ATTR_ENV = 'dd.env'
        LOG_ATTR_SERVICE = 'dd.service'
        LOG_ATTR_SPAN_ID = 'dd.span_id'
        LOG_ATTR_TRACE_ID = 'dd.trace_id'
        LOG_ATTR_VERSION = 'dd.version'
        LOG_ATTR_SOURCE = 'ddsource'

        attr_reader \
          :env,
          :service,
          :span_id,
          :version

        # @!visibility private
        def initialize(
          env: nil,
          service: nil,
          span_id: nil,
          trace_id: nil,
          version: nil
        )
          # Dup and freeze strings so they aren't modified by reference.
          @env = env || Datadog.configuration.env
          @service = service || Datadog.configuration.service
          @span_id = (span_id || 0).to_s
          @trace_id = trace_id || 0
          @version = version || Datadog.configuration.version
        end

        def to_h
          @to_h ||= {
            # Adds IDs as tags to log output
            dd: {
              # To preserve precision during JSON serialization, use strings for large numbers
              env: env.to_s,
              service: service.to_s,
              version: version.to_s,
              trace_id: trace_id.to_s,
              span_id: span_id.to_s
            },
            ddsource: Core::Logging::Ext::DD_SOURCE
          }
        end

        # This method (#to_log_format) implements an algorithm by prefixing keys for nested values
        # but the algorithm makes the constants implicit. Hence, we use it for validation during test.
        def to_log_format
          @log_format ||= begin
            attributes = []
            attributes << "#{LOG_ATTR_ENV}=#{env}" unless env.nil?
            attributes << "#{LOG_ATTR_SERVICE}=#{service}"
            attributes << "#{LOG_ATTR_VERSION}=#{version}" unless version.nil?
            attributes << "#{LOG_ATTR_TRACE_ID}=#{trace_id}"
            attributes << "#{LOG_ATTR_SPAN_ID}=#{span_id}"
            attributes << "#{LOG_ATTR_SOURCE}=#{Core::Logging::Ext::DD_SOURCE}"
            attributes.join(' ')
          end
        end

        def trace_id
          Correlation.format_trace_id(@trace_id)
        end
      end

      module_function

      # Produces a CorrelationIdentifier from the TraceDigest provided
      #
      # DEV: can we memoize this object, give it can be common to
      # use a correlation multiple times, specially in the context of logging?
      # @!visibility private
      def identifier_from_digest(digest)
        return Identifier.new unless digest

        Identifier.new(
          span_id: digest.span_id,
          trace_id: digest.trace_id,
        )
      end

      def format_trace_id(trace_id)
        if Datadog.configuration.tracing.trace_id_128_bit_logging_enabled
          format_trace_id_128(trace_id)
        else
          Tracing::Utils::TraceId.to_low_order(trace_id).to_s
        end
      end

      def format_trace_id_128(trace_id)
        if !Tracing::Utils::TraceId.to_high_order(trace_id).zero?
          Kernel.format('%032x', trace_id)
        else
          Tracing::Utils::TraceId.to_low_order(trace_id).to_s
        end
      end
    end
  end
end
