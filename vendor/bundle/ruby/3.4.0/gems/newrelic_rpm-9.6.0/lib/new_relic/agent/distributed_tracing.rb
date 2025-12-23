# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'distributed_tracing/cross_app_payload'
require_relative 'distributed_tracing/cross_app_tracing'

require_relative 'distributed_tracing/distributed_trace_transport_type'
require_relative 'distributed_tracing/distributed_trace_payload'

require_relative 'distributed_tracing/trace_context'

module NewRelic
  module Agent
    #
    # This module contains helper methods related to Distributed
    # Tracing, an APM feature that ties together traces from multiple
    # apps in one view.  Use it to add distributed tracing to protocols
    # not already supported by the agent.
    #
    # @api public
    module DistributedTracing
      extend NewRelic::SupportabilityHelper
      extend self

      # Adds the Distributed Trace headers so that the downstream service can participate in a
      # distributed trace. This method should be called every time an outbound call is made
      # since the header payload contains a timestamp.
      #
      # Distributed Tracing must be enabled to use this method.
      #
      # +insert_distributed_trace_headers+ always inserts W3C trace context headers and inserts
      # New Relic distributed tracing header by default. New Relic headers may be suppressed by
      # setting +exclude_new_relic_header+ to +true+ in your configuration file.
      #
      # @param headers           [Hash]     Is a Hash to which the distributed trace headers
      #                                     will be inserted.
      #
      # @return           {Transaction}     The transaction the headers were inserted from,
      #                                     or +nil+ if headers were not inserted.
      #
      # @api public
      #
      def insert_distributed_trace_headers(headers = {})
        record_api_supportability_metric(:insert_distributed_trace_headers)

        unless Agent.config[:'distributed_tracing.enabled']
          NewRelic::Agent.logger.warn('Not configured to insert distributed trace headers')
          return nil
        end

        return unless valid_api_argument_class?(headers, 'headers', Hash)

        return unless transaction = Transaction.tl_current

        transaction.distributed_tracer.insert_headers(headers)
        transaction
      rescue => e
        NewRelic::Agent.logger.error('error during insert_distributed_trace_headers', e)
        nil
      end

      # Accepts distributed tracing headers from any source that has been packaged
      # as a Ruby Hash, thereby allowing the user to manually inject distributed
      # tracing headers.  It is optimized to process +HTTP_TRACEPARENT+, +HTTP_TRACESTATE+,
      # and +HTTP_NEWRELIC+ as the given Hash keys.  which is the most common scenario
      # from Rack middleware in most Ruby applications.  However, the Hash keys are
      # case-insensitive and the "HTTP_" prefixes may also be omitted.
      #
      # Calling this method is not necessary in a typical HTTP trace as
      # distributed tracing is already handled by the agent.
      #
      # When used, invoke this method as early as possible in a transaction's life-cycle
      # as calling after the headers are already created will have no effect.
      #
      # This method accepts both W3C trace context and New Relic distributed tracing headers.
      # When both are present, only the W3C headers are utilized.  When W3C trace context
      # headers are present, New Relic headers are ignored regardless if W3C trace context
      # headers are valid and parsable.
      #
      # @param headers         [Hash]     Incoming distributed trace headers as a Ruby
      #                                   Hash object.  Hash keys are expected to be one of
      #                                   +TRACEPARENT+, +TRACESTATE+, +NEWRELIC+ and are
      #                                   case-insensitive, with or without "HTTP_" prefixes.
      #
      #                                   either as a JSON string or as a
      #                                   header-friendly string returned from
      #                                   {DistributedTracePayload#http_safe}
      #
      # @param transport_type  [String]   May be one of:  +HTTP+, +HTTPS+, +Kafka+, +JMS+,
      #                                   +IronMQ+, +AMQP+, +Queue+, +Other+.  Values are
      #                                   case sensitive.  All other values result in +Unknown+
      #
      # @return {Transaction} if successful, +nil+ otherwise
      #
      # @api public
      #
      def accept_distributed_trace_headers(headers, transport_type = NewRelic::HTTP)
        record_api_supportability_metric(:accept_distributed_trace_headers)

        unless Agent.config[:'distributed_tracing.enabled']
          NewRelic::Agent.logger.warn('Not configured to accept distributed trace headers')
          return nil
        end

        return unless valid_api_argument_class?(headers, 'headers', Hash)
        return unless valid_api_argument_class?(transport_type, 'transport_type', String)

        return unless transaction = Transaction.tl_current

        # assume we have Rack conforming keys when transport_type is HTTP(S)
        # otherwise, fish for key/value pairs regardless of prefix and case-sensitivity.
        hdr = if transport_type.start_with?(NewRelic::HTTP)
          headers
        else
          # start with the most common case first
          hdr = {
            NewRelic::HTTP_TRACEPARENT_KEY => headers[NewRelic::TRACEPARENT_KEY],
            NewRelic::HTTP_TRACESTATE_KEY => headers[NewRelic::TRACESTATE_KEY],
            NewRelic::HTTP_NEWRELIC_KEY => headers[NewRelic::NEWRELIC_KEY]
          }

          # when not found, search for any casing for trace context headers, ignoring potential prefixes
          hdr[NewRelic::HTTP_TRACEPARENT_KEY] ||= variant_key_value(headers, NewRelic::TRACEPARENT_KEY)
          hdr[NewRelic::HTTP_TRACESTATE_KEY] ||= variant_key_value(headers, NewRelic::TRACESTATE_KEY)
          hdr[NewRelic::HTTP_NEWRELIC_KEY] ||= variant_key_value(headers, NewRelic::CANDIDATE_NEWRELIC_KEYS)
          hdr
        end

        transaction.distributed_tracer.accept_incoming_request(hdr, transport_type)
        transaction
      rescue => e
        NewRelic::Agent.logger.error('error during accept_distributed_trace_headers', e)
        nil
      end

      private

      def has_variant_key?(key, variants)
        key.to_s.downcase.end_with?(*Array(variants))
      end

      def variant_key_value(headers, variants)
        (headers.detect { |k, v| has_variant_key?(k, variants) } || NewRelic::EMPTY_ARRAY)[1]
      end
    end
  end
end
