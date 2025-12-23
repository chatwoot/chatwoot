# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Rack
        # Rack integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_RACK_ENABLED'
          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_RACK_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_RACK_ANALYTICS_SAMPLE_RATE'
          RACK_ENV_REQUEST_SPAN = 'datadog.rack_request_span'
          SPAN_HTTP_PROXY_REQUEST = 'http.proxy.request'
          SPAN_HTTP_PROXY_QUEUE = 'http.proxy.queue'
          SPAN_REQUEST = 'rack.request'
          TAG_COMPONENT = 'rack'
          TAG_COMPONENT_HTTP_PROXY = 'http_proxy'
          TAG_OPERATION_REQUEST = 'request'
          TAG_OPERATION_HTTP_PROXY_REQUEST = 'request'
          TAG_OPERATION_HTTP_PROXY_QUEUE = 'queue'
          TAG_OPERATION_HTTP_SERVER_QUEUE = 'queue'
          WEBSERVER_APP = 'webserver'
          DEFAULT_PEER_WEBSERVER_SERVICE_NAME = 'web-server'
        end
      end
    end
  end
end
