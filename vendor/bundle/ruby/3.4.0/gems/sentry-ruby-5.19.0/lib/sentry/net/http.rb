# frozen_string_literal: true

require "net/http"
require "resolv"
require "sentry/utils/http_tracing"

module Sentry
  # @api private
  module Net
    module HTTP
      include Utils::HttpTracing

      OP_NAME = "http.client"
      SPAN_ORIGIN = "auto.http.net_http"
      BREADCRUMB_CATEGORY = "net.http"

      # To explain how the entire thing works, we need to know how the original Net::HTTP#request works
      # Here's part of its definition. As you can see, it usually calls itself inside a #start block
      #
      # ```
      # def request(req, body = nil, &block)
      #   unless started?
      #     start {
      #       req['connection'] ||= 'close'
      #       return request(req, body, &block) # <- request will be called for the second time from the first call
      #     }
      #   end # .....
      # end
      # ```
      #
      # So we're only instrumenting request when `Net::HTTP` is already started
      def request(req, body = nil, &block)
        return super unless started? && Sentry.initialized?
        return super if from_sentry_sdk?

        Sentry.with_child_span(op: OP_NAME, start_timestamp: Sentry.utc_now.to_f, origin: SPAN_ORIGIN) do |sentry_span|
          request_info = extract_request_info(req)

          if propagate_trace?(request_info[:url])
            set_propagation_headers(req)
          end

          res = super
          response_status = res.code.to_i

          if record_sentry_breadcrumb?
            record_sentry_breadcrumb(request_info, response_status)
          end

          if sentry_span
            set_span_info(sentry_span, request_info, response_status)
          end

          res
        end
      end

      private

      def from_sentry_sdk?
        dsn = Sentry.configuration.dsn
        dsn && dsn.host == self.address
      end

      def extract_request_info(req)
        # IPv6 url could look like '::1/path', and that won't parse without
        # wrapping it in square brackets.
        hostname = address =~ Resolv::IPv6::Regex ? "[#{address}]" : address
        uri = req.uri || URI.parse("#{use_ssl? ? 'https' : 'http'}://#{hostname}#{req.path}")
        url = "#{uri.scheme}://#{uri.host}#{uri.path}" rescue uri.to_s

        result = { method: req.method, url: url }

        if Sentry.configuration.send_default_pii
          result[:query] = uri.query
          result[:body] = req.body
        end

        result
      end
    end
  end
end

Sentry.register_patch(:http, Sentry::Net::HTTP, Net::HTTP)
