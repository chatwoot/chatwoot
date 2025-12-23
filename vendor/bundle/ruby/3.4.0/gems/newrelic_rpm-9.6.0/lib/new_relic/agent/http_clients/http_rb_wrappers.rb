# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'abstract'

module NewRelic
  module Agent
    module HTTPClients
      class HTTPResponse < AbstractResponse
        def [](key)
          _, value = @wrapped_response.headers.find { |k, _| key.casecmp(k) == 0 }
          value unless value.nil?
        end

        def to_hash
          @wrapped_response.headers
        end
      end

      class HTTPRequest < AbstractRequest
        HTTP_RB = 'http.rb'
        HOST = 'host'
        COLON = ':'

        def initialize(wrapped_request)
          @wrapped_request = wrapped_request
        end

        def uri
          @uri ||= URIUtil.parse_and_normalize_url(@wrapped_request.uri)
        end

        def type
          HTTP_RB
        end

        def host_from_header
          if hostname = self[HOST]
            hostname.split(COLON).first
          end
        end

        def host
          host_from_header || @wrapped_request.host
        end

        def method
          @wrapped_request.verb.upcase
        end

        def [](key)
          @wrapped_request.headers[key]
        end

        def []=(key, value)
          @wrapped_request.headers[key] = value
        end

        def headers
          @wrapped_request.headers.to_hash
        end
      end
    end
  end
end
