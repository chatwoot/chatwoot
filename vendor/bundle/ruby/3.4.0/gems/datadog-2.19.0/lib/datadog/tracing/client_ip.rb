# frozen_string_literal: true

require_relative '../core/configuration'
require_relative '../core/utils/network'
require_relative 'metadata/ext'
require_relative 'span'

module Datadog
  module Tracing
    # Common functions for supporting the `http.client_ip` span attribute.
    module ClientIp
      class << self
        # Sets the `http.client_ip` tag on the given span.
        #
        # This function respects the user's settings: if they disable the client IP tagging,
        #   or provide a different IP header name.
        #
        # @param [Span] span The span that's associated with the request.
        # @param [HeaderCollection, #get, nil] headers A collection with the request headers.
        # @param [String, nil] remote_ip The remote IP the request associated with the span is sent to.
        def set_client_ip_tag(span, headers: nil, remote_ip: nil)
          return unless configuration.enabled

          set_client_ip_tag!(span, headers: headers, remote_ip: remote_ip)
        end

        # Forcefully sets the `http.client_ip` tag on the given span.
        #
        # This function ignores the user's `enabled` setting.
        #
        # @param [Span] span The span that's associated with the request.
        # @param [HeaderCollection, #get, nil] headers A collection with the request headers.
        # @param [String, nil] remote_ip The remote IP the request associated with the span is sent to.
        def set_client_ip_tag!(span, headers: nil, remote_ip: nil)
          ip = extract_client_ip(headers, remote_ip)

          span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_CLIENT_IP, ip) if ip
        end

        def extract_client_ip(headers, remote_ip)
          if headers && configuration.header_name
            return Datadog::Core::Utils::Network.stripped_ip_from_request_headers(
              headers,
              ip_headers_to_check: Array(configuration.header_name)
            )
          end

          ip_from_headers = Datadog::Core::Utils::Network.stripped_ip_from_request_headers(headers) if headers

          ip_from_headers || Datadog::Core::Utils::Network.stripped_ip(remote_ip)
        end

        private

        def configuration
          Datadog.configuration.tracing.client_ip
        end
      end
    end
  end
end
