# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module Memcache
    module Tracer
      SLASH = '/'
      UNKNOWN = 'unknown'
      LOCALHOST = 'localhost'
      MULTIGET_METRIC_NAME = 'get_multi_request'
      MEMCACHED = 'Memcached'
      INSTRUMENTATION_NAME = 'Dalli'

      def with_newrelic_tracing(operation, *args)
        NewRelic::Agent.record_instrumentation_invocation(INSTRUMENTATION_NAME)

        segment = NewRelic::Agent::Tracer.start_datastore_segment(
          product: MEMCACHED,
          operation: operation
        )

        begin
          NewRelic::Agent::Tracer.capture_segment_error(segment) { yield }
        ensure
          if NewRelic::Agent.config[:capture_memcache_keys]
            segment.notice_nosql_statement("#{operation} #{args.first.inspect}")
          end
          ::NewRelic::Agent::Transaction::Segment.finish(segment)
        end
      end

      def server_for_key_with_newrelic_tracing
        NewRelic::Agent.record_instrumentation_invocation(INSTRUMENTATION_NAME)

        yield.tap do |server|
          begin
            if txn = ::NewRelic::Agent::Tracer.current_transaction
              segment = txn.current_segment
              if ::NewRelic::Agent::Transaction::DatastoreSegment === segment
                assign_instance_to(segment, server)
              end
            end
          rescue => e
            ::NewRelic::Agent.logger.warn("Unable to set instance info on datastore segment: #{e.message}")
          end
        end
      end

      def get_multi_with_newrelic_tracing(method_name)
        NewRelic::Agent.record_instrumentation_invocation(INSTRUMENTATION_NAME)

        segment = NewRelic::Agent::Tracer.start_segment(
          name: "Ruby/Memcached/Dalli/#{method_name}"
        )

        begin
          NewRelic::Agent::Tracer.capture_segment_error(segment) { yield }
        ensure
          ::NewRelic::Agent::Transaction::Segment.finish(segment)
        end
      end

      def send_multiget_with_newrelic_tracing(keys)
        NewRelic::Agent.record_instrumentation_invocation(INSTRUMENTATION_NAME)

        segment = ::NewRelic::Agent::Tracer.start_datastore_segment(
          product: MEMCACHED,
          operation: MULTIGET_METRIC_NAME
        )

        begin
          assign_instance_to(segment, self)
          NewRelic::Agent::Tracer.capture_segment_error(segment) { yield }
        ensure
          if ::NewRelic::Agent.config[:capture_memcache_keys]
            segment.notice_nosql_statement("#{MULTIGET_METRIC_NAME} #{keys.inspect}")
          end
          ::NewRelic::Agent::Transaction::Segment.finish(segment)
        end
      end

      def assign_instance_to(segment, server)
        host = port_path_or_id = nil
        if server.hostname.start_with?(SLASH)
          host = LOCALHOST
          port_path_or_id = server.hostname
        else
          host = server.hostname
          port_path_or_id = server.port
        end
        segment.set_instance_info(host, port_path_or_id)
      rescue => e
        ::NewRelic::Agent.logger.debug("Failed to retrieve memcached instance info: #{e.message}")
        segment.set_instance_info(UNKNOWN, UNKNOWN)
      end
    end
  end
end
