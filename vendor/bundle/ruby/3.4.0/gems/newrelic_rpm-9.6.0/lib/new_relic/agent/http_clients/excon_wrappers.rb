# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'abstract'

module NewRelic
  module Agent
    module HTTPClients
      class ExconHTTPResponse < AbstractResponse
        def initialize(wrapped_response)
          super(wrapped_response)

          # Since HTTP headers are case-insensitive, we normalize all of them to
          # upper case here, and then also in our [](key) implementation.
          @normalized_headers = {}
          (get_attribute(:headers) || {}).each do |key, val|
            @normalized_headers[key.upcase] = val
          end
        end

        def [](key)
          @normalized_headers[key.upcase]
        end

        def to_hash
          @normalized_headers.dup
        end

        private

        def get_attribute(name)
          if @wrapped_response.respond_to?(name)
            @wrapped_response.send(name)
          else
            @wrapped_response[name]
          end
        end

        def get_status_code
          code = get_attribute(:status).to_i
          code == 0 ? nil : code
        end
      end

      class ExconHTTPRequest < AbstractRequest
        attr_reader :method

        EXCON = 'Excon'
        LHOST = 'host'
        UHOST = 'Host'
        COLON = ':'

        def initialize(datum)
          @datum = datum

          @method = @datum[:method].to_s.upcase
          @scheme = @datum[:scheme]
          @port = @datum[:port]
          @path = @datum[:path]
        end

        def type
          EXCON
        end

        def host_from_header
          if hostname = (headers[LHOST] || headers[UHOST])
            hostname.split(COLON).first
          end
        end

        def host
          host_from_header || @datum[:host]
        end

        def [](key)
          headers[key]
        end

        def []=(key, value)
          headers[key] = value
        end

        def uri
          url = "#{@scheme}://#{host}:#{@port}#{@path}"
          URIUtil.parse_and_normalize_url(url)
        end

        def headers
          @datum[:headers]
        end
      end
    end
  end
end
