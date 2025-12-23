# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'abstract'

module NewRelic
  module Agent
    module HTTPClients
      class TyphoeusHTTPResponse < AbstractResponse
        def [](key)
          unless headers.nil?
            result = headers[key]

            # Typhoeus 0.5.3 has a bug where asking the headers hash for a
            # nonexistent header will return the hash itself, not what we want.
            result == headers ? nil : result
          end
        end

        def to_hash
          hash = {}
          headers.each do |(k, v)|
            hash[k] = v
          end
          hash
        end

        private

        def headers
          @wrapped_response.headers
        end
      end

      class TyphoeusHTTPRequest < AbstractRequest
        def initialize(request)
          @request = request
          @uri = case request.url
            when ::URI then request.url
            else NewRelic::Agent::HTTPClients::URIUtil.parse_and_normalize_url(request.url)
          end
        end

        TYPHOEUS = 'Typhoeus'.freeze

        def type
          TYPHOEUS
        end

        LHOST = 'host'.freeze
        UHOST = 'Host'.freeze

        def host_from_header
          self[LHOST] || self[UHOST]
        end

        def host
          host_from_header || @uri.host
        end

        GET = 'GET'.freeze

        def method
          (@request.options[:method] || GET).to_s.upcase
        end

        def [](key)
          return nil unless @request.options && headers

          headers[key]
        end

        def []=(key, value)
          headers[key] = value
        end

        def headers
          @request.options[:headers] || {}
        end

        def uri
          @uri
        end
      end
    end
  end
end
