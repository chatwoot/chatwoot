# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative '../../datastores/nosql_obfuscator'

module NewRelic::Agent::Instrumentation
  module Elasticsearch
    PRODUCT_NAME = 'Elasticsearch'
    OPERATION = 'perform_request'
    INSTRUMENTATION_NAME = NewRelic::Agent.base_name(name)

    def perform_request_with_tracing(method, path, params = {}, body = nil, headers = nil)
      return yield unless NewRelic::Agent::Tracer.tracing_enabled?

      NewRelic::Agent.record_instrumentation_invocation(INSTRUMENTATION_NAME)

      segment = NewRelic::Agent::Tracer.start_datastore_segment(
        product: PRODUCT_NAME,
        operation: nr_operation || OPERATION,
        host: nr_hosts[:host],
        port_path_or_id: nr_hosts[:port],
        database_name: nr_cluster_name
      )
      begin
        NewRelic::Agent::Tracer.capture_segment_error(segment) { yield }
      ensure
        if segment
          segment.notice_nosql_statement(nr_reported_query(body || params))
          segment.finish
        end
      end
    end

    private

    def nr_operation
      operation_index = caller_locations.index do |line|
        string = line.to_s
        string.include?('lib/elasticsearch/api') && !string.include?(OPERATION)
      end
      return nil unless operation_index

      caller_locations[operation_index].to_s.split('`')[-1].gsub(/\W/, '')
    end

    def nr_reported_query(query)
      return unless NewRelic::Agent.config[:'elasticsearch.capture_queries']
      return query unless NewRelic::Agent.config[:'elasticsearch.obfuscate_queries']

      NewRelic::Agent::Datastores::NosqlObfuscator.obfuscate_statement(query)
    end

    def nr_cluster_name
      return @nr_cluster_name if @nr_cluster_name
      return if nr_hosts.empty?

      NewRelic::Agent.disable_all_tracing do
        @nr_cluster_name ||= perform_request('GET', '_cluster/health').body['cluster_name']
      end
    rescue StandardError => e
      NewRelic::Agent.logger.error('Failed to get cluster name for elasticsearch', e)
      nil
    end

    def nr_hosts
      @nr_hosts ||= (transport.hosts.first || NewRelic::EMPTY_HASH)
    end
  end
end
