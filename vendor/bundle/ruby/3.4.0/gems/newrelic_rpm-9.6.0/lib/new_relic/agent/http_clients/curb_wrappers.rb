# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'abstract'

module NewRelic
  module Agent
    module HTTPClients
      class CurbRequest
        CURB = 'Curb'
        LHOST = 'host'
        UHOST = 'Host'

        def initialize(curlobj)
          @curlobj = curlobj
        end

        def type
          CURB
        end

        def host_from_header
          self[LHOST] || self[UHOST]
        end

        def host
          host_from_header || self.uri.host
        end

        def method
          @curlobj._nr_http_verb
        end

        def [](key)
          headers[key]
        end

        def []=(key, value)
          headers[key] = value
        end

        def uri
          @uri ||= URIUtil.parse_and_normalize_url(@curlobj.url)
        end

        def headers
          @curlobj.headers
        end
      end

      class CurbResponse < AbstractResponse
        def initialize(wrapped_response)
          super(wrapped_response)
          @headers = {}
        end

        def [](key)
          @headers[key.downcase]
        end

        def to_hash
          @headers.dup
        end

        def append_header_data(data)
          key, value = data.split(/:\s*/, 2)
          @headers[key.downcase] = value
          @wrapped_response._nr_header_str ||= +''
          @wrapped_response._nr_header_str << data
        end

        private

        def get_status_code
          get_status_code_using(:response_code)
        end
      end
    end
  end
end
