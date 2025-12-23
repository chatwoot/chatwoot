# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'abstract'

module NewRelic
  module Agent
    module HTTPClients
      class HTTPClientResponse < AbstractResponse
        def [](key)
          @wrapped_response.headers.each do |k, v|
            if key.casecmp(k) == 0
              return v
            end
          end
          nil
        end

        def to_hash
          @wrapped_response.headers
        end
      end

      class HTTPClientRequest < AbstractRequest
        attr_reader :request

        HTTP_CLIENT = 'HTTPClient'.freeze
        LHOST = 'host'.freeze
        UHOST = 'Host'.freeze
        COLON = ':'.freeze

        def initialize(request)
          @request = request
        end

        def type
          HTTP_CLIENT
        end

        def method
          request.header.request_method
        end

        def host_from_header
          if hostname = (self[LHOST] || self[UHOST])
            hostname.split(COLON).first
          end
        end

        def host
          host_from_header || uri.host.to_s
        end

        def uri
          @uri ||= URIUtil.parse_and_normalize_url(request.header.request_uri)
        end

        def [](key)
          headers[key]
        end

        def []=(key, value)
          request.http_header[key] = value
        end

        def headers
          request.headers
        end
      end
    end
  end
end
