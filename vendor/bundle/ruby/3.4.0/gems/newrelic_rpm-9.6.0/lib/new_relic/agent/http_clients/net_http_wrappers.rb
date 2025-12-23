# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'abstract'
require 'resolv'

module NewRelic
  module Agent
    module HTTPClients
      class NetHTTPResponse < AbstractResponse
        def [](key)
          @wrapped_response[key]
        end

        def to_hash
          @wrapped_response.to_hash
        end
      end

      class NetHTTPRequest < AbstractRequest
        def initialize(connection, request)
          @connection = connection
          @request = request
        end

        NET_HTTP = 'Net::HTTP'

        def type
          NET_HTTP
        end

        HOST = 'host'
        COLON = ':'

        def host_from_header
          if hostname = self[HOST]
            hostname.split(COLON).first
          end
        end

        def host
          host_from_header || @connection.address
        end

        def method
          @request.method
        end

        def [](key)
          @request[key]
        end

        def []=(key, value)
          @request[key] = value
        end

        def uri
          case @request.path
          when /^https?:\/\//
            ::NewRelic::Agent::HTTPClients::URIUtil.parse_and_normalize_url(@request.path)
          else
            connection_address = @connection.address
            if Resolv::IPv6::Regex.match?(connection_address)
              connection_address = "[#{connection_address}]"
            end

            scheme = @connection.use_ssl? ? 'https' : 'http'
            ::NewRelic::Agent::HTTPClients::URIUtil.parse_and_normalize_url(
              "#{scheme}://#{connection_address}:#{@connection.port}#{@request.path}"
            )
          end
        end

        def headers
          @request.instance_variable_get(:@header)
        end
      end
    end
  end
end
