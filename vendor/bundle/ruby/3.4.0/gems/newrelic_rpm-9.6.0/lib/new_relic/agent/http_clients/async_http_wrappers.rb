# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'abstract'
require 'resolv'

module NewRelic
  module Agent
    module HTTPClients
      class AsyncHTTPResponse < AbstractResponse
        def get_status_code
          get_status_code_using(:status)
        end

        def [](key)
          to_hash[key.downcase]&.first
        end

        def to_hash
          @wrapped_response.headers.to_h
        end
      end

      class AsyncHTTPRequest < AbstractRequest
        def initialize(connection, method, url, headers)
          @connection = connection
          @method = method
          @url = ::NewRelic::Agent::HTTPClients::URIUtil.parse_and_normalize_url(url)
          @headers = headers
        end

        ASYNC_HTTP = 'Async::HTTP'
        LHOST = 'host'
        UHOST = 'Host'
        COLON = ':'

        def type
          ASYNC_HTTP
        end

        def host_from_header
          if hostname = (self[LHOST] || self[UHOST])
            hostname.split(COLON).first
          end
        end

        def host
          host_from_header || uri.host.to_s
        end

        def [](key)
          return headers[key] unless headers.is_a?(Array)

          headers.each do |header|
            return header[1] if header[0].casecmp?(key)
          end
          nil
        end

        def []=(key, value)
          if headers.is_a?(Array)
            headers << [key, value]
          else
            headers[key] = value
          end
        end

        def uri
          @url
        end

        def headers
          @headers
        end

        def method
          @method
        end
      end
    end
  end
end
