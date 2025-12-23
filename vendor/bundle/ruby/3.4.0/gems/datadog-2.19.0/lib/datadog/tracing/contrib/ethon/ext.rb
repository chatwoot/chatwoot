# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Ethon
        # Ethon integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_ETHON_ENABLED'
          ENV_SERVICE_NAME = 'DD_TRACE_ETHON_SERVICE_NAME'
          ENV_PEER_SERVICE = 'DD_TRACE_ETHON_PEER_SERVICE'

          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_ETHON_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_ETHON_ANALYTICS_SAMPLE_RATE'
          DEFAULT_PEER_SERVICE_NAME = 'ethon'
          SPAN_REQUEST = 'ethon.request'
          SPAN_MULTI_REQUEST = 'ethon.multi.request'
          NOT_APPLICABLE_METHOD = 'N/A'
          TAG_COMPONENT = 'ethon'
          TAG_OPERATION_REQUEST = 'request'
          TAG_OPERATION_MULTI_REQUEST = 'multi.request'
          PEER_SERVICE_SOURCES = Array[
            Tracing::Metadata::Ext::TAG_PEER_HOSTNAME,
            Tracing::Metadata::Ext::NET::TAG_DESTINATION_NAME,
            Tracing::Metadata::Ext::NET::TAG_TARGET_HOST,].freeze
        end
      end
    end
  end
end
