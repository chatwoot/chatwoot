# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'abstract'

module NewRelic
  module Agent
    module HTTPClients
      # HTTPX returns an instance of HTTPX::ErrorResponse on error,
      # and that instance itself yields the underlying HTTP response
      # object via #response, but depending on the error that HTTP
      # response object could be unset.
      class HTTPXErrorResponse
        def status; end
        def headers; {}; end
      end

      class HTTPXHTTPResponse < AbstractResponse
        def initialize(response)
          if response.is_a?(::HTTPX::ErrorResponse)
            @response = response.response || HTTPXErrorResponse.new
          else
            @response = response
          end
        end

        def status_code
          @response.status
        end

        def [](key)
          headers[format_key(key)]
        end

        def headers
          headers ||= @response.headers.to_hash.each_with_object({}) do |(k, v), h|
            h[format_key(k)] = v
          end
        end
        alias to_hash headers

        private

        def format_key(key)
          key.tr('-', '_').downcase
        end
      end

      class HTTPXHTTPRequest < AbstractRequest
        attr_reader :uri

        DEFAULT_HOST = 'UNKNOWN_HOST'
        TYPE = 'HTTPX'
        LHOST = 'host'.freeze
        UHOST = 'Host'.freeze

        def initialize(request)
          @request = request
          @uri = request.uri
        end

        def type
          TYPE
        end

        def host_from_header
          self[LHOST] || self[UHOST]
        end

        def host
          host_from_header || uri.host&.downcase || DEFAULT_HOST
        end

        def method
          @request.verb
        end

        def []=(key, value)
          @request.headers[key] = value
        end

        def headers
          @request.headers
        end

        def [](key)
          @request.headers[key]
        end
      end
    end
  end
end
