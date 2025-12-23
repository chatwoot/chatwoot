# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Httprb
        # Httprb integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_HTTPRB_ENABLED'
          ENV_SERVICE_NAME = 'DD_TRACE_HTTPRB_SERVICE_NAME'
          ENV_PEER_SERVICE = 'DD_TRACE_HTTPRB_PEER_SERVICE'
          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_HTTPRB_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_HTTPRB_ANALYTICS_SAMPLE_RATE'
          ENV_ERROR_STATUS_CODES = 'DD_TRACE_HTTPRB_ERROR_STATUS_CODES'
          DEFAULT_PEER_SERVICE_NAME = 'httprb'
          SPAN_REQUEST = 'httprb.request'
          TAG_COMPONENT = 'httprb'
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
