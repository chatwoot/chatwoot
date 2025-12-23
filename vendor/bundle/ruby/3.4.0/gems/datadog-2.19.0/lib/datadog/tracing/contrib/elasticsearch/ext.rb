# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Elasticsearch
        # Elasticsearch integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_ELASTICSEARCH_ENABLED'
          ENV_SERVICE_NAME = 'DD_TRACE_ELASTICSEARCH_SERVICE_NAME'
          ENV_PEER_SERVICE = 'DD_TRACE_ELASTICSEARCH_PEER_SERVICE'
          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_ELASTICSEARCH_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_ELASTICSEARCH_ANALYTICS_SAMPLE_RATE'
          DEFAULT_PEER_SERVICE_NAME = 'elasticsearch'
          SPAN_QUERY = 'elasticsearch.query'
          SPAN_TYPE_QUERY = 'elasticsearch'
          TAG_BODY = 'elasticsearch.body'
          TAG_METHOD = 'elasticsearch.method'
          TAG_PARAMS = 'elasticsearch.params'
          TAG_URL = 'elasticsearch.url'
          TAG_COMPONENT = 'elasticsearch'
          TAG_OPERATION_QUERY = 'query'
          TAG_SYSTEM = 'elasticsearch'
          PEER_SERVICE_SOURCES = Array[
            Tracing::Metadata::Ext::TAG_PEER_HOSTNAME,
            Tracing::Metadata::Ext::NET::TAG_DESTINATION_NAME,
            Tracing::Metadata::Ext::NET::TAG_TARGET_HOST,].freeze
        end
      end
    end
  end
end
