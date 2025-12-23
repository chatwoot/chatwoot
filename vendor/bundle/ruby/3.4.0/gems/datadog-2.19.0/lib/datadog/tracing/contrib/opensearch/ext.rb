# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module OpenSearch
        # OpenSearch integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_OPENSEARCH_ENABLED'
          ENV_SERVICE_NAME = 'DD_TRACE_OPENSEARCH_SERVICE_NAME'
          ENV_PEER_SERVICE = 'DD_TRACE_OPENSEARCH_PEER_SERVICE'
          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_OPENSEARCH_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_OPENSEARCH_ANALYTICS_SAMPLE_RATE'
          ENV_RESOURCE_PATTERN = 'DD_TRACE_OPENSEARCH_RESOURCE_PATTERN'
          ABSOLUTE_RESOURCE_PATTERN = 'absolute'
          RELATIVE_RESOURCE_PATTERN = 'relative'
          VALID_RESOURCE_PATTERNS = [
            ABSOLUTE_RESOURCE_PATTERN,
            RELATIVE_RESOURCE_PATTERN
          ].freeze
          # Default should be changed to RELATIVE in 3.0 to match the Elasticsearch integration
          DEFAULT_RESOURCE_PATTERN = ABSOLUTE_RESOURCE_PATTERN
          DEFAULT_PEER_SERVICE_NAME = 'opensearch'
          SPAN_QUERY = 'opensearch.query'
          SPAN_TYPE_QUERY = 'opensearch'
          TAG_COMPONENT = 'opensearch'
          TAG_SYSTEM = 'opensearch'
          TAG_METHOD = 'http.method'
          TAG_PATH = 'http.url_details.path'
          TAG_PARAMS = 'opensearch.params'
          TAG_BODY = 'opensearch.body'
          TAG_URL = 'http.url'
          TAG_HOST = 'http.url_details.host'
          TAG_PORT = 'http.url_details.port'
          TAG_SCHEME = 'http.url_details.scheme'
          TAG_RESPONSE_CONTENT_LENGTH = 'http.response.content_length'
          PEER_SERVICE_SOURCES = Array[
            Tracing::Metadata::Ext::TAG_PEER_HOSTNAME,
            Tracing::Metadata::Ext::NET::TAG_DESTINATION_NAME,
            Tracing::Metadata::Ext::NET::TAG_TARGET_HOST,].freeze
        end
      end
    end
  end
end
