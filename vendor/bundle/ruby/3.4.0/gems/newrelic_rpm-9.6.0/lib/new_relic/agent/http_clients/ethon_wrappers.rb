# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'uri'
require_relative 'abstract'

module NewRelic
  module Agent
    module HTTPClients
      class EthonHTTPResponse < AbstractResponse
        def initialize(easy)
          @easy = easy
        end

        def status_code
          @easy.response_code
        end

        def [](key)
          headers[format_key(key)]
        end

        def headers
          # Ethon::Easy#response_headers will return '' if headers are unset
          @easy.response_headers.scan(/\n([^:]+?): ([^:\n]+?)\r/).each_with_object({}) do |pair, hash|
            hash[format_key(pair[0])] = pair[1]
          end
        end
        alias to_hash headers

        private

        def format_key(key)
          key.tr('-', '_').downcase
        end
      end

      class EthonHTTPRequest < AbstractRequest
        attr_reader :uri

        DEFAULT_ACTION = 'GET'
        DEFAULT_HOST = 'UNKNOWN_HOST'
        ETHON = 'Ethon'
        LHOST = 'host'.freeze
        UHOST = 'Host'.freeze

        def initialize(easy)
          @easy = easy
          @uri = uri_from_easy
        end

        def type
          ETHON
        end

        def host_from_header
          self[LHOST] || self[UHOST]
        end

        def uri_from_easy
          # anticipate `Ethon::Easy#url` being `example.com` without a protocol
          # defined and use an 'http' protocol prefix for `URI.parse` to work
          # with the URL as desired
          url_str = @easy.url.match?(':') ? @easy.url : "http://#{@easy.url}"
          begin
            URI.parse(url_str)
          rescue URI::InvalidURIError => e
            NewRelic::Agent.logger.debug("Failed to parse URI '#{url_str}': #{e.class} - #{e.message}")
            URI.parse(NewRelic::EMPTY_STR)
          end
        end

        def host
          host_from_header || uri.host&.downcase || DEFAULT_HOST
        end

        def method
          return DEFAULT_ACTION unless @easy.instance_variable_defined?(action_instance_var)

          @easy.instance_variable_get(action_instance_var)
        end

        def action_instance_var
          NewRelic::Agent::Instrumentation::Ethon::Easy::ACTION_INSTANCE_VAR
        end

        def []=(key, value)
          headers[key] = value
          @easy.headers = headers
        end

        def headers
          @headers ||= if @easy.instance_variable_defined?(headers_instance_var)
            @easy.instance_variable_get(headers_instance_var)
          else
            {}
          end
        end

        def headers_instance_var
          NewRelic::Agent::Instrumentation::Ethon::Easy::HEADERS_INSTANCE_VAR
        end

        def [](key)
          headers[key]
        end
      end
    end
  end
end
