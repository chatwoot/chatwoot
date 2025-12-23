# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Httpclient
        # Httpclient integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_HTTPCLIENT_ENABLED'
          ENV_SERVICE_NAME = 'DD_TRACE_HTTPCLIENT_SERVICE_NAME'
          ENV_PEER_SERVICE = 'DD_TRACE_HTTPCLIENT_PEER_SERVICE'

          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_HTTPCLIENT_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_HTTPCLIENT_ANALYTICS_SAMPLE_RATE'
          ENV_ERROR_STATUS_CODES = 'DD_TRACE_HTTPCLIENT_ERROR_STATUS_CODES'
          DEFAULT_PEER_SERVICE_NAME = 'httpclient'
          SPAN_REQUEST = 'httpclient.request'
          TAG_COMPONENT = 'httpclient'
          TAG_OPERATION_REQUEST = 'request'
          PEER_SERVICE_SOURCES = Array[
            Tracing::Metadata::Ext::TAG_PEER_HOSTNAME,
            Tracing::Metadata::Ext::NET::TAG_DESTINATION_NAME,
            Tracing::Metadata::Ext::NET::TAG_TARGET_HOST,].freeze
        end
      end
    end
  end
end
